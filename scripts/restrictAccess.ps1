

function Add-CTMRestrictIPs {
    param (
        [Parameter(Mandatory=$true)]
        $resourceGroupName,
        [Parameter(Mandatory=$true)]
        $serviceName
    )
    
    $gatewayWebApp = "$serviceName-gateway-webapp"
    Write-Host "Getting outbound IPs of Primary Gateway..." -NoNewline
    $ips = (Get-AzWebApp -ResourceGroup $resourceGroupName -name $gatewayWebApp).OutboundIpAddresses.Split(',')
    Write-Host "Done" -ForegroundColor Green    
    foreach  ($ip in $ips) {
        Add-RestrictRule -resourceGroupName $resourceGroupName -appName "$serviceName-ctm-qe-webapp" -ip $ip
        Add-RestrictRule -resourceGroupName $resourceGroupName -appName "$serviceName-ctm-disq-webapp" -ip $ip
        Add-RestrictRule -resourceGroupName $resourceGroupName -appName "$serviceName-ayalon-webapp" -ip $ip
    }

    Write-Host "Getting outbound IPs of Secondary Gateway..." -NoNewline
    $ips = (Get-AzWebAppSlot -ResourceGroup $resourceGroupName -name $gatewayWebApp -Slot secondary).OutboundIpAddresses.Split(',')
    Write-Host "Done" -ForegroundColor Green    
    foreach  ($ip in $ips) {
        Add-RestrictRule -resourceGroupName $resourceGroupName -appName "$serviceName-ctm-qe-webapp-s" -ip $ip
        Add-RestrictRule -resourceGroupName $resourceGroupName -appName "$serviceName-ctm-disq-webapp-s" -ip $ip
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