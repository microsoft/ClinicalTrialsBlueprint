
param(
    [Parameter(Mandatory=$true)]
    [String] 
    $name,
    
    [Parameter()]
    [String]
    [ValidateSet('free','s1','s2','s3','s4','s5')] 
    $planId = "free"
)

. ./profile.ps1



$context = Get-AzContext
$subscriptionId = $context.subscription.id

function New-HbsSaaSApplication() {
    param(
        $resourceName,        
        $subscriptionId,
        $planId,
        $offerId
    )    

    $accessToken = Get-AzBearerToken

    $headers = @{
        Authorization = $accessToken
    }
    $data = @{
        Properties = @{
            PublisherId            = "microsoft-hcb"
            OfferId                = $offerId
            SaasResourceName       = $resourceName
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
        $location = $result.Headers['location'];
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
        if ($operationStatus.properties.status -eq "PendingFulfillmentStart") {
            return $operationStatus
        }
        else {
            Write-Error "Failed to create" $resourceName
        }
    }
}

New-HbsSaaSApplication -resourceName $name -subscriptionId $subscriptionId -planId $planId -offerId microsofthealthcarebot