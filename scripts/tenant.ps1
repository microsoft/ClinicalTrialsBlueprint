#$onboardingEndpoint = "https://admin.healthbot-dev.microsoft.com/api"
$onboardingEndpoint = "http://localhost:8083/api"

function New-HbsTenant {
    param (
        [Parameter(Mandatory)]
        [string]
        $name,
        $tenantId,
        $saasSubscriptionId,
        $planId,
        $offerId,
        $location,
        $instrumentationKey
    )

    $body = @{
        name               = $tenantId
        friendly_name      = $name
        email              = (Get-AzContext).Account.Id
        usermanagement     = "portal"
        saasSubscriptionId = $saasSubscriptionId
        planId             = $planId
        offerId            = $offerId
        location           = $location
        instrumentationKey = $instrumentationKey
    } | ConvertTo-Json

    $headers = @{
        Authorization = Get-AzBearerToken
    }

    $result = Invoke-WebRequest -Uri $onboardingEndpoint/saas/tenants/?api-version=2019-07-01 `
        -Method "post" `
        -ContentType "application/json" `
        -Headers $headers `
        -Body $body
    $tenant = ConvertFrom-Json $result.Content                
    return $tenant
}

function Restore-HbsTenant($tenant, $location, $data, $saasSubscriptionId) {

    $body = @{
        account = $tenant
        location = $location
        saasSubscriptionId = $saasSubscriptionId
        data = $data | ConvertFrom-Json
    } | ConvertTo-Json -Depth 10

    $headers = @{
        Authorization = Get-AzBearerToken
    }

    $result = Invoke-WebRequest -Uri $onboardingEndpoint/saas/restore/?api-version=2019-07-01 `
        -Method "post" `
        -ContentType "application/json" `
        -Headers $headers `
        -Body $body
    $tenant = ConvertFrom-Json $result.Content                
    return $tenant
}
