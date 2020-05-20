. ./scripts/profile.ps1

function ChangeConfig(
	[Parameter(Mandatory=$true)]
	$resourceGroupName,
	[Parameter(Mandatory=$true)]
	$serviceName
)
{
	Write-Host "Changing Config $serviceName..."
	
  $subscriptionId = (Get-AzContext).Subscription.Id
	$primaryAci = "$serviceName-ctm-struct-aci"
	$secondaryAci = "$serviceName-ctm-struct-aci-s"
	$gatewayWebApp = "$serviceName-gateway-webapp"

	$stopped = IsAciStopped -resourceGroupName $resourceGroupName -aciName $primaryAci
	if(-Not $stopped) {
		Write-Host "Cannot change config when a container group is running $primaryAci" -ForegroundColor Red 
		return
	} 
	Write-Host "$primaryAci is stopped, continuing..." -ForegroundColor Green 
	
	$stopped = IsAciStopped -resourceGroupName $resourceGroupName -aciName $primaryAci
	if(-Not $stopped) {
		Write-Host "Cannot change config when a container group is running $secondaryAci" -ForegroundColor Red 
		return
	}
	Write-Host "$secondaryAci is stopped, continuing..." -ForegroundColor Green

	$isPrimary = IsCurrentSlotPrimary -gatewayWebApp $gatewayWebApp

	Write-Host "deploying primary resources"

	# deploy the primary resources
	$matchingOutput = New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -serviceName $serviceName `
		-TemplateFile ".\arm-templates\azuredeploy-ctm.json" -TemplateParameterFile ".\arm-templates\azuredeploy-ctm.parameters.json" 

	# stopping the primary slot's aci
	if ($isPrimary) {
		StopAci -resourceGroupName $resourceGroupName -aciName $primaryAci
	}

	Write-Host "deploying secondary resources"

	# deploy the secondary resources
	$matchingOutput = New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -serviceName $serviceName `
		-TemplateFile ".\arm-templates\azuredeploy-ctm.json" -TemplateParameterFile ".\arm-templates\azuredeploy-ctm.parameters.json" `
		-isSecondary $true 

	# stopping the primary slot's aci
	if (-Not $isPrimary) {
		StopAci -resourceGroupName $resourceGroupName -aciName $secondaryAci
	}

	Write-Host "Config change finished successfully." -ForegroundColor Green	
}

function IsAciStopped (
	[Parameter(Mandatory=$true)]
	$resourceGroupName,	
	[Parameter(Mandatory=$true)]
	$aciName
)
{
	$headers = @{
		Authorization = Get-AzBearerToken
	}
	$aciDetails = Invoke-WebRequest -Uri "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.ContainerInstance/containerGroups/$aciName/?api-version=2018-10-01" `
																				  -Method "get" `
																					-Headers $headers
	$content = $aciDetails.Content | ConvertFrom-Json
	return $content.properties.instanceView.state -eq "Stopped"
}

function IsCurrentSlotPrimary(
	[Parameter(Mandatory=$true)]
	$gatewayWebApp
)
{
	$gatewayDetails = Invoke-WebRequest -Uri "https://$gatewayWebApp.azurewebsites.net/slot" `
																			-Method "get"
	$content = $gatewayDetails.Content | ConvertFrom-Json
	return $content.slot -eq "primary"
}

function StopAci(
	[Parameter(Mandatory=$true)]
	$resourceGroupName, 
	[Parameter(Mandatory=$true)]
	$aciName
) 
{
    Write-Host "Stopping ACI $aciName..."
    $headers = @{
        Authorization = Get-AzBearerToken
    }
    $subscriptionId = (Get-AzContext).Subscription.Id
    
    Invoke-WebRequest -Uri "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.ContainerInstance/containerGroups/$aciName/stop?api-version=2018-10-01" `
                        -Method "post" `
                        -Headers $headers
    Write-Host "Done stopping $aciName" -ForegroundColor Green                    
}