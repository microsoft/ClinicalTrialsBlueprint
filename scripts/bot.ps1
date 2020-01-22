
<#
.SYNOPSIS
Created Bot Channel Registration ARM resource

.DESCRIPTION
Long description

.PARAMETER displayName
Parameter description

.PARAMETER botId
Parameter description

.PARAMETER appId
Parameter description

.PARAMETER subscriptionId
Parameter description

.PARAMETER resourceGroup
Parameter description

.PARAMETER planId
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>

function New-HbsBotRegistration {
    param (
        $displayName,
        $botId,
        $appId,
        $subscriptionId,
        $resourceGroup,
        $planId
    )
    
    $headers = @{
        Authorization = Get-AzBearerToken
    }

    $sku = "F0"
    $endpoint = "https://bot-api-us.healthbot-$env.microsoft.com/bot/dynabot/$botId"
    if ($planId -ne "free") {
        $sku = "S1"
        $endpoint = "https://bot-api-us.healthbot-$env.microsoft.com/bot-premium/dynabot/$botId"
    }

    $body = @{
        location   = "global"
        sku        = @{
            name = $sku
        }
        kind       = "bot"
        properties = @{
            name               = $botId
            displayName        = $displayName
            endpoint           = $endpoint
            msaAppId           = $appId
            enabledChannels    = @("webchat", "directline","msteams")
            configuredChannels = @("webchat", "directline","msteams")
        }
    } | ConvertTo-Json

    $result = Invoke-WebRequest `
        -Uri "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.BotService/botServices/$botId/?api-version=2017-12-01" `
        -Method "put" `
        -ContentType "application/json" `
        -Headers $headers `
        -Body $body 
    $botRegistration = ConvertFrom-Json $result.Content 
    return $botRegistration
}

function Get-HbsWebchatSecret {
    param (
        $resourceId
    )
    $headers = @{
        Authorization = Get-AzBearerToken
    }

    $result = Invoke-WebRequest -Uri "https://management.azure.com/$resourceId/channels/WebChatChannel/listChannelWithKeys/?api-version=2017-12-01" `
        -Method "post" `
        -ContentType "application/json" `
        -Headers $headers
    $botChannel = ConvertFrom-Json $result.Content                
    return $botChannel.properties.properties.sites[0].key
}
