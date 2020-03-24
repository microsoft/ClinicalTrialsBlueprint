

function Add-HbsRestrictIPs {
    param (
        [Parameter(Mandatory=$true)]
        $resourceGroupName,
        [Parameter(Mandatory=$true)]
        $serviceName,
        [Parameter(Mandatory=$true)]
        $fhirResoureGroupName,
        [Parameter(Mandatory=$true)]
        $fhirServiceName
    )
    
    $gatewayWebApp = "$serviceName-gateway-webapp"
    Write-Host "Getting outbound IPs of Gateway..." -NoNewline
    $ips = (Get-AzWebApp -ResourceGroup $resourceGroupName -name $gatewayWebApp).OutboundIpAddresses.Split(',')
    Write-Host "Done" -ForegroundColor Green    
    foreach  ($ip in $ips) {
        Add-RestrictRule -resourceGroupName $resourceGroupName -appName "$serviceName-ctm-qe-webapp" -ip $ip
        Add-RestrictRule -resourceGroupName $resourceGroupName -appName "$serviceName-ctm-dcs-webapp" -ip $ip
        Add-RestrictRule -resourceGroupName $resourceGroupName -appName "$serviceName-ctm-disq-webapp" -ip $ip
        Add-RestrictRule -resourceGroupName $resourceGroupName -appName "$serviceName-ayalon-webapp" -ip $ip
        Add-RestrictRule -resourceGroupName $fhirResoureGroupName -appName $fhirServiceName -ip $ip
    }
}


function Add-RestrictRule() {
    param(
        $resourceGroupName, $appName, $ip
    )
    Write-Host "Restrcting "$appName "to " $ip "..." -NoNewline
    Add-AzWebAppAccessRestrictionRule -ResourceGroupName $resourceGroupName `
                                      -WebAppName $appName `
                                      -name "ip rule" -Priority 100 `
                                      -Action Allow -IpAddress $ip"/32"
    Write-Host "Done" -ForegroundColor Green                                      
}