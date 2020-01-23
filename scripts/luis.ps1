
function Get-LuisApplicationByName($appName, $location, $authKey) {
    $headers = @{
        "Ocp-Apim-Subscription-Key" = $authKey
    }
    $result = Invoke-WebRequest  -Uri "https://$location.api.cognitive.microsoft.com/luis/api/v2.0/apps" `
                       -Method "get" `
                       -ContentType "application/json" `
                       -Headers $headers 

    $luisApplicationResult = ConvertFrom-Json $result.Content

    $app = $luisApplicationResult | Where-Object {$_.name -eq $appName}

    return $app                     
}

function Import-LuisApplication($appName, $luisJSON, $location, $authKey) {

    $headers = @{
        "Ocp-Apim-Subscription-Key" = $authKey
    }
     
    $result = Invoke-WebRequest  -Uri "https://$location.api.cognitive.microsoft.com/luis/api/v2.0/apps/import?appName=$appName" `
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
