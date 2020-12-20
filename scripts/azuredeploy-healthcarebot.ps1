param(
    [Parameter(Mandatory=$true)]
    $saasSubscriptionId,
    [Parameter(Mandatory=$true)]
    [String]
    $botServiceName,
    [Parameter(Mandatory=$true)]
    [String]
    $serviceName,
    [Parameter(Mandatory=$true)]
    [ValidateSet("US","EU")]
    $botLocation,
    [Parameter(Mandatory=$true)]
    $ResourceGroup,
    [Parameter(Mandatory=$true)]
    $matchingOutput,
    [boolean]
    $isSecondary = $false,
    [Parameter(Mandatory=$false)]
    $resourceTags,
    [Parameter()]
    $TemplateParameterFile = './arm-templates/azuredeploy-healthcarebot-parameters.json'
    
)

$matchingOutputs = $matchingOutput.Outputs

. ./scripts/profile.ps1
. ./scripts/luis.ps1
. ./scripts/tenant.ps1

$context = Get-AzContext
$subscriptionId = $context.subscription.id


$luisPath = "./lu"
$restorePath = "./bot-templates"



Try {
    
    $parms = @{
           'botServiceName' = $botServiceName;
           'isSecondary' = $isSecondary;
		   'ResourceGroupName' = $ResourceGroup;
           'saasSubscriptionId' = $saasSubscriptionId;
           'TemplateParameterFile' = $TemplateParameterFile;
           'serviceName' = $serviceName;
           'TemplateFile'='./arm-templates/azuredeploy-healthcarebot.json'
          }
		  
    if ($null -ne $resourceTags){
        $parms.resourceTags = $resourceTags`
    }


    
    Write-Host "Running Template Deployment..."
    $output = New-AzResourceGroupDeployment @parms

    $output
    $luisAuthLocation = $output.Parameters.luisAuthLocation.Value
    
    $tenantId = $output.Outputs["serviceUniqueName"].Value    

    Write-Host "Creating Healthcare Bot Tenant $tenantId..." -NoNewline
    $saasTenant = New-HbsTenant -name $botServiceName -tenantId $tenantId `
                                -saasSubscriptionId $saasSubscriptionId `
                                -location $botLocation `
                                -instrumentationKey $output.Outputs["instrumentationKey"].Value
    $saasTenant

    # Uploads all the LUIS files. Each file is a luis application
    $luisApplications = @{}
    Get-ChildItem -Path $luisPath | ForEach-Object {
        Write-Host "Get LUI Application '"$_.BaseName "'..." -NoNewline       
        $luisApplication = Get-LuisApplicationByName -appName $_.BaseName -location $luisAuthLocation `
                                                     -authKey $output.Outputs["luisAuthotingKey"].Value
        if ($null -eq $luisApplication) {    
            Write-Host "Not found - Importing LUIS Application from " $_.BaseName "..." -NoNewline
            $luisJSON = Get-Content -Raw -Path $_.FullName -Encoding UTF8
            $luisApplicationId = Import-LuisApplication -appName $_.BaseName -luisJSON $luisJSON -location $luisAuthLocation  `
                                                        -authKey $output.Outputs["luisAuthotingKey"].Value
            Write-Host "Done" -ForegroundColor Green
        } else {
            $luisApplicationId = $luisApplication.id
            Write-Host "Done" -ForegroundColor Green
        }                                                    
        $luisApplications[$_.BaseName] = $luisApplicationId
        
        Write-Host "Assigning LUIS app " $_.BaseName " to LUIS account..." -NoNewline
        $assignLuisApp = Set-LuisApplicationAccount -appId $luisApplicationId -subscriptionId $subscriptionId `
                            -resourceGroup $ResourceGroup -accountName $botServiceName"-prediction" `
                            -location $luisAuthLocation -authKey $output.Outputs["luisAuthotingKey"].Value

        Write-Host "Done" -ForegroundColor Green
        Write-Host "Training LUIS app " $_.BaseName "..."  -NoNewline
        $trainResult = Invoke-TrainLuisApplication -appId $luisApplicationId -version "0.1" -location $luisAuthLocation `
                                    -authKey $output.Outputs["luisAuthotingKey"].Value
        if ($trainResult.status -ne "UpToDate") {
            Write-Host "Waiting to finish training..." -NoNewline
            $waitForTraningToFinish = $true
            while ($waitForTraningToFinish) {
                $trainStatus = Get-LuisApplicationTrainingStatus -appId $luisApplicationId -version "0.1" `
                                                                 -location $luisAuthLocation `
                                                                 -authKey $output.Outputs["luisAuthotingKey"].Value                                                                                
                $trainStatus | ForEach-Object {
                    if ($_.details.status -ne "Success") {
                        Write-Host "..." -NoNewline
                        Start-Sleep -Seconds 2
                        continue
                    }
                }
                $waitForTraningToFinish = $false                                                                                
            }
        }
        Write-Host "Done" -ForegroundColor Green        
        Write-Host "Publishing LUIS app " $_.BaseName  "... " -NoNewline
       
        $publishResult = Publish-LuisApplication -appId $luisApplicationId -version "0.1" -location $luisAuthLocation `
                                                 -authKey $output.Outputs["luisAuthotingKey"].Value                                                         
        Write-Host "Published " -ForegroundColor Green        
    }

    $luisPredictionLocation = (Get-AzResourceGroup -Name $ResourceGroup).Location

    # Restore all the hbs templates
    Get-ChildItem -Path $restorePath | ForEach-Object {
        Write-Host "Importing template from " $_.BaseName "..." -NoNewline
        $restoreJSON = Get-Content -Raw -Path $_.FullName

        # Here you need to replace the place holders with real data

        $restoreJSON = $restoreJSON.Replace('{ctm-api-key}', $matchingOutputs.proxyApiKey.Value)
        $restoreJSON = $restoreJSON.Replace('{qe-baseurl}', $matchingOutputs.gatewayEndpoint.Value)
        $restoreJSON = $restoreJSON.Replace('{dcs-baseurl}', $matchingOutputs.gatewayEndpoint.Value)
        $restoreJSON = $restoreJSON.Replace('{disq-baseurl}', $matchingOutputs.gatewayEndpoint.Value)
        $restoreJSON = $restoreJSON.Replace('{luisApplicationId}', $luisApplications["metadata_clinical_trials"])
        $restoreJSON = $restoreJSON.Replace('{luisPredictionKey}', $output.Outputs["luisPredictionKey"].Value)
        $restoreJSON = $restoreJSON.Replace('{luisLocation}', $luisPredictionLocation)

        $saasTenant = Restore-HbsTenant -location $botLocation -tenant $saasTenant `
                                        -data $restoreJSON -saasSubscriptionId $saasSubscriptionId
        Write-Host "Done" -ForegroundColor Green
    }

    $webchatSecret = $saasTenant.webchat_secret

    if ($botLocation -eq 'US') {
        $portalEndpoint = "https://us.healthbot.microsoft.com/account"
    }
    else {
        $portalEndpoint = "https://eu.healthbot.microsoft.com/account"
    }


	
    Select-Object @{n = "portal"; e = {"$portalEndpoint/$tenantId"}},
                  @{n = "SaaSApplication"; e = {"https://ms.portal.azure.com/#@/resource/providers/Microsoft.SaaS/saasresources/$saasSubscriptionId/overview"}},
                  @{n = "WebChat"; e ={"https://hatenantstorageprod.blob.core.windows.net/public-websites/webchat/index.html?s=$webchatSecret"}} -InputObject ""

        if($isSecondary){	
            # update functional-tests app with bot name and secret
            #get bot settings
            Write-Host "updating bot function test app with bot tenant id: $tenantId"
            $funcTestApp = Get-AzWebApp -ResourceGroupName $ResourceGroup -Name $output.Outputs.funcTestsServiceName.Value
            $settings =  $funcTestApp.SiteConfig.AppSettings
            $hashTable = @{}
            $settings | ForEach-Object {
                $hashTable[$_.Name] = $_.Value
            }

            #set default bot value
            $hashTable
            $hashTable["DefaultBot"] = $tenantId
            
            # set secret value
            $secrets = ConvertFrom-Json $hashTable["SECRETS"]
            $secrets | Add-Member -NotePropertyName $tenantId -NotePropertyValue $webchatSecret
            $hashTable["SECRETS"] = ConvertTo-Json $secrets
            $hashTable["SECRETS"] = $hashTable["SECRETS"].ToString()

            #set bot settings
            Set-AzWebApp -ResourceGroupName $ResourceGroup -Name $output.Outputs.funcTestsServiceName.Value -AppSettings $hashTable
        }
}    
Catch {
    Write-Host
    Write-Error -Exception $_.Exception 
	Write-Error -Exception $_.ScriptStackTrace 
}    
