function New-HbsSaaSApplication() {
    param(
        $ResourceName,        
        $SubscriptionId,
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
            SaasResourceName       = $ResourceName
            SKUId                  = $planId
            PaymentChannelType     = "SubscriptionDelegated"
            Quantity               = 1
            TermId                 = "hjdtn7tfnxcy"
            PaymentChannelMetadata = @{
                AzureSubscriptionId = $SubscriptionId
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
            Write-Error "Failed to create" $ResourceName
        }
    }
}
