function Import-LuisApplication($luisJSON, $location, $authKey) {

    $headers = @{
        "Ocp-Apim-Subscription-Key" = $authKey
    }
     
    $result = Invoke-WebRequest  -Uri "https://$location.api.cognitive.microsoft.com/luis/api/v2.0/apps/import" `
                       -Method "post" `
                       -ContentType "application/json" `
                       -Headers $headers `
                       -Body $luisJSON

    $luisApplicationResult = ConvertFrom-Json $result.Content    
    return $luisApplicationResult                     
}

function Set-LuisApplicationAccount($appId, $subscriptionId, $resourceGroup, $accountName, $location, $authKey) {

    $headers = @{
        "Ocp-Apim-Subscription-Key" = $authKey
        Authorization = Get-AzBearerToken
    }

    $body = @{
        azureSubscriptionId = $subscriptionId
        resourceGroup = $resourceGroup
        accountName = $accountName
    } | ConvertTo-Json

    $result = Invoke-WebRequest -Uri "https://$location.api.cognitive.microsoft.com/luis/api/v2.0/apps/$appId/azureaccounts" `
                            -Method "post" `
                            -ContentType "application/json" `
                            -Headers $headers `
                            -Body $body 
    $assignResult = ConvertFrom-Json $result.Content    
    return $assignResult
}
