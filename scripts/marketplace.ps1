<#
    .SYNOPSIS
    Create SaaS Marketplace resource that will be used for charging for the Healthcare Bot Service 
#>

. ./scripts/profile.ps1

function New-HbsSaaSApplication() {
    param(
        [Parameter(Mandatory=$true)]
        [String]
        $name,     
        [Parameter()]
        [String]
        [ValidateSet('free','s1','s2','s3','s4','s5')]   
        $planId = "free",
        $offerId = "microsofthealthcarebot"
    )    

    $context = Get-AzContext
    $subscriptionId = $context.subscription.id

    $accessToken = Get-AzBearerToken

    $headers = @{
        Authorization = $accessToken
    }
    $data = @{
        Properties = @{
            PublisherId            = "microsoft-hcb"
            OfferId                = $offerId
            SaasResourceName       = $name
            SKUId                  = $planId
            PaymentChannelType     = "SubscriptionDelegated"
            Quantity               = 1
            TermId                 = "hjdtn7tfnxcy"
            PaymentChannelMetadata = @{
                AzureSubscriptionId = $subscriptionId
            }
        }
    }
    $body = $data | ConvertTo-Json
    $result = Invoke-WebRequest -Uri https://management.azure.com/providers/microsoft.saas/saasresources?api-version=2018-03-01-beta  `
        -Method 'put' -Headers $headers `
        -Body $body -ContentType "application/json"

    if ($result.StatusCode -eq 202) {
        if ($result.Headers['location'] -is [array]) {
            $location = $result.Headers['location'][0];
        }
        else {
            $location = $result.Headers['location'];
        }
        $r = Invoke-WebRequest -Uri $location -Method 'get' -Headers $headers -ContentType "application/json"
        if ($null -eq $r) {
            return
        }
        while ($r.StatusCode -ne 200) {
            Write-Host "." -NoNewline
            Start-Sleep -Seconds 1 
            $r = Invoke-WebRequest -Uri $location -Method 'get' -Headers $headers -ContentType "application/json"
        }
        $operationStatus = ConvertFrom-Json $r.Content
        Write-Host
        if ($operationStatus.properties.status -eq "PendingFulfillmentStart") {
            $id = Split-Path $operationStatus.id -Leaf
            return $id
        }
        else {
            Write-Error "Failed to create" $name
        }
    }
}

function Get-HbsSaaSApplication() {
    $accessToken = Get-AzBearerToken

    $headers = @{
        Authorization = $accessToken
    }
    $result = Invoke-WebRequest -Uri https://management.azure.com/providers/microsoft.saas/saasresources?api-version=2018-03-01-beta  `
    -Method 'get' -Headers $headers `
    -Body $body -ContentType "application/json"
    $saasApplications = ConvertFrom-Json $result.Content 
    return $saasApplications.value
}
