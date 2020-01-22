. ./profile.ps1
. ./utils.ps1
. ./marketplace.ps1
. ./luis.ps1
. ./bot.ps1
. ./tenant.ps1
. ./ad.ps1

Write-Host  "Running CTM-Blueprint..." -ForegroundColor Green
$context = Get-AzContext
$userId = $context.Account.id
$subscriptionId = $context.subscription.id
$planId = "free"
$offerId = "microsofthealthcarebot"
$luisAuthLocation = "westus"
$env="-dev"
$portalEndpoint = "https://us.healthbot$env.microsoft.com/account"
$hbsLocation = "US"
$luisAppFile = "../lu/LUIS.Triage.json"
$restorePath = "../bot-templates/teams-handoff.json"


$objectId =$(Get-AzureADUser -Filter "UserPrincipalName eq '$userId'").ObjectId
Write-Host ObjectId: $objectId

Try {
    $resourceGroup = "CTM-Blueprint"
    Write-Host "Running Template Deplpyment"
    $output = New-AzResourceGroupDeployment -ResourceGroupName $resourceGroup -TemplateFile "../arm-templates/azuredeploy.json" -objectId $objectId
    $output
    
    $tenantId = $output.Outputs["serviceUniqueName"].Value
    Write-Host "Creating SaaS Marketplace offering $offerId..." -NoNewline

    #$marketplaceApp = New-HbsSaaSApplication -ResourceName $tenantId -planId $planId -offerId $offerId -SubscriptionId $subscriptionId
    #$marketplaceApp

    #$saasSubscriptionId = Split-Path $marketplaceApp.id -Leaf
    $saasSubscriptionId = "1dc0e142-d927-c863-8dda-d33313c03004"

    Write-Host "Creating HBS Tenant $tenantId..." -NoNewline
    $saasTenant = New-HbsTenant -name $output.Parameters["serviceName"].Value -tenantId $tenantId `
        -saasSubscriptionId $saasSubscriptionId `
        -planId $planId -offerId $offerId `
        -location $hbsLocation `
        -instrumentationKey $output.Outputs["instrumentationKey"].Value
    $saasTenant

    
    Write-Host "Importing LUIS Application from $luisAppFile..." -NoNewline
    $luisJSON = Get-Content -Raw -Path $luisAppFile
    $luisApplicationId = Import-LuisApplication -luisJSON $luisJSON -location $luisAuthLocation -authKey $output.Outputs["luisAuthotingKey"].Value
    Write-Host "Done" -ForegroundColor Green

    Write-Host "Assigning LUIS app to LUIS account..." -NoNewline
    $assignLuisApp = Set-LuisApplicationAccount -appId $luisApplicationId -subscriptionId $subscriptionId `
                        -resourceGroup $resourceGroup -accountName $tenantId"-prediction" -location $luisAuthLocation -authKey $output.Outputs["luisAuthotingKey"].Value
    Write-Host "Done" -ForegroundColor Green

    Write-Host "Importing template from $restorePath..." -NoNewline
    $restoreJSON = Get-Content -Raw -Path $restorePath

    $saasTenant = Restore-HbsTenant -location $hbsLocation -tenant $saasTenant -data $restoreJSON -saasSubscriptionId $saasSubscriptionId
    Write-Host "Done" -ForegroundColor Green
    $saasTenant

    Write-Host "Your Healthcare Bot is now ready! You can access various resources below:" -ForegroundColor Green
    Write-Host " - Management Portal: " $portalEndpoint/$tenantId -ForegroundColor Green
    Write-Host " - Marketplace SaaS Application: https://ms.portal.azure.com/#@/resource/providers/Microsoft.SaaS/saasresources/$saasSubscriptionId/overview" -ForegroundColor Green
    Write-Host " - Teams Channel Client: https://teams.microsoft.com/l/chat/0/0?users=28:$appId" -ForegroundColor Green
    Write-Host " - WebChat Client: https://hatenantstorageprod.blob.core.windows.net/public-websites/webchat/index.html?s=$webchatSecret" -ForegroundColor Green

}    
Catch {
    Write-Host
    Write-Error -Exception $_.Exception    
}    
