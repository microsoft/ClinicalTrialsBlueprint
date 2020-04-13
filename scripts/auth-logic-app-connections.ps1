Param(
    [Parameter(Mandatory=$true)]
    $ResourceGroupName,
    [Parameter(Mandatory=$true)]
    $ResourceLocation,
    [Parameter(Mandatory=$true)]
    [ValidateSet('office365','arm')]   
    $api,
    [Parameter(Mandatory=$true)]
    $ConnectionName,
    [Parameter(Mandatory=$true)]
    $subscriptionId
)
#region mini window, made by Scripting Guy Blog
Function Show-OAuthWindow {
    Add-Type -AssemblyName System.Windows.Forms
 
    $form = New-Object -TypeName System.Windows.Forms.Form -Property @{Width = 600; Height = 800 }
    $web = New-Object -TypeName System.Windows.Forms.WebBrowser -Property @{Width = 580; Height = 780; Url = ($url -f ($Scope -join "%20")) }
    $DocComp = {
        $Global:uri = $web.Url.AbsoluteUri
        if ($Global:Uri -match "error=[^&]*|code=[^&]*") { $form.Close() }
    }
    $web.ScriptErrorsSuppressed = $true
    $web.Add_DocumentCompleted($DocComp)
    $form.Controls.Add($web)
    $form.Add_Shown( { $form.Activate() })
    $form.ShowDialog() | Out-Null
}
#endregion


#select the subscription

#if the connection wasn't alrady created via a deployment
$connection = Get-AzResource -ResourceType "Microsoft.Web/connections" -ResourceGroupName $ResourceGroupName -ResourceName $ConnectionName

Write-Host "connection status: " $connection.Properties.Statuses[0]

$parameters = @{
    "parameters" = , @{
        "parameterName" = "token";
        "redirectUrl"   = "https://ema1.exp.azure.com/ema/default/authredirect";
        "tenantId" = "6d093b87-2b09-4e56-95ba-6d3e1e5fcea2";
    }
}

#get the links needed for consent
$consentResponse = Invoke-AzResourceAction -Action "listConsentLinks" -ResourceId $connection.ResourceId -Parameters $parameters -Force

$url = $consentResponse.Value.Link 

#prompt user to login and grab the code after auth
Show-OAuthWindow -URL $url

$regex = '(code=)(.*)$'
$code = ($uri | Select-string -pattern $regex).Matches[0].Groups[2].Value
Write-output "Received an accessCode: $code"

if (-Not [string]::IsNullOrEmpty($code)) {
    $parameters = @{ }
    $parameters.Add("code", $code)
    # NOTE: errors ignored as this appears to error due to a null response

    #confirm the consent code
    Invoke-AzResourceAction -Action "confirmConsentCode" -ResourceId $connection.ResourceId -Parameters $parameters -Force -ErrorAction Ignore
}

#retrieve the connection
$connection = Get-AzResource -ResourceType "Microsoft.Web/connections" -ResourceGroupName $ResourceGroupName -ResourceName $ConnectionName
Write-Host "connection status now: " $connection.Properties.Statuses[0]