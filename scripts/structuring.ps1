. ./scripts/profile.ps1

<#
.SYNOPSIS
Restart CTM Structuring service
.DESCRIPTION
Pulls the structuring docker images and restarts the structuring process
.PARAMETER resourceGroupName
Resource Group Name of the container group
.PARAMETER containerGroupName
Container Group Name
#>
function Restart-CtmStructuring(
    [Parameter(Mandatory=$true)]
    $resourceGroupName, 
    [Parameter(Mandatory=$true)]
    $containerGroupName) 
{
    Write-Host "Restarting ACI $containerGroupName..." -NoNewline
    $headers = @{
        Authorization = Get-AzBearerToken
    }
    $subscriptionId = (Get-AzContext).Subscription.Id
    
    Invoke-WebRequest  -Uri "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.ContainerInstance/containerGroups/$containerGroupName/restart?api-version=2018-10-01" `
                        -Method "post" `
                        -Headers $headers
    Write-Host "Done" -ForegroundColor Green                                 
}

<#
.SYNOPSIS
Stops CTM Structuring service
.DESCRIPTION
.PARAMETER resourceGroupName
Resource Group Name of the container group
.PARAMETER containerGroupName
Container Group Name
#>
function Stop-CtmStructuring(
    [Parameter(Mandatory=$true)]
    $resourceGroupName, 
    [Parameter(Mandatory=$true)]
    $containerGroupName) 
{
    Write-Host "Stopping ACI $containerGroupName..." -NoNewline
    $headers = @{
        Authorization = Get-AzBearerToken
    }
    $subscriptionId = (Get-AzContext).Subscription.Id
    
    Invoke-WebRequest  -Uri "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.ContainerInstance/containerGroups/$containerGroupName/stop?api-version=2018-10-01" `
                        -Method "post" `
                        -Headers $headers
    Write-Host "Done" -ForegroundColor Green                                     
}


<#
.SYNOPSIS
Starts CTM Structuring service
.DESCRIPTION
Pulls the structuring docker images and starts the structuring process
.PARAMETER resourceGroupName
Resource Group Name of the container group
.PARAMETER containerGroupName
Container Group Name
#>
function Start-CtmStructuring(
    [Parameter(Mandatory=$true)]
    $resourceGroupName, 
    [Parameter(Mandatory=$true)]
    $containerGroupName) 
{
    Write-Host "Starting ACI $containerGroupName..." -NoNewline
    $headers = @{
        Authorization = Get-AzBearerToken
    }
    $subscriptionId = (Get-AzContext).Subscription.Id
    
    Invoke-WebRequest  -Uri "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.ContainerInstance/containerGroups/$containerGroupName/start?api-version=2018-10-01" `
                        -Method "post" `
                        -Headers $headers
    Write-Host "Done" -ForegroundColor Green                                     
}
