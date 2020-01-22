
. ./profile.ps1
. ./utils.ps1
. ./marketplace.ps1
. ./luis.ps1
. ./bot.ps1
. ./tenant.ps1
. ./ad.ps1


$Name = "CTM-Bot"
$tenantId = Get-HbsUniqueTenantId -Name $Name
$resourceGroup = "CTM-Blueprint"
$context = Get-AzContext
$subscriptionId = $context.subscription.id
$planId = "free"
$offerId = "microsofthealthcarebot"
$location = "US"
$ds_location = "eastus"
$luisAuthLocation = "westus"
$env = "dev"
$luisAppFile = "../lu/LUIS.Triage.json"
$restorePath = "../bot-templates/teams-handoff.json"
$portalEndpoint = "https://us.healthbot-$env.microsoft.com/account"

$createTenantOnly = $false

Try {

    if ($createTenantOnly -eq $false) {
        Write-Host "Creating/Using ResourceGroup $resourceGroup..." -NoNewline
        $rg = New-ResourceGroupIfNeeded -resourceGroup $resourceGroup -location $ds_location    
        Write-Host "Done $($rg.ResourceGroupName)" -ForegroundColor Green
        
        Write-Host "Creating LUIS Authoring Account $tenantId-authoring..." -NoNewline
        $luisAuthoring = New-AzCognitiveServicesAccount -ResourceGroupName $resourceGroup -Name $tenantId-authoring `
                        -Type LUIS.Authoring -SkuName "F0" -Location $luisAuthLocation -ErrorAction Stop
        $luisAuthoringKey = Get-AzCognitiveServicesAccountKey -ResourceGroupName $resourceGroup -Name $tenantId-authoring                
        Write-Host "Done $($luisAuthoring.AccountName)" -ForegroundColor Green
        
        Write-Host "Creating LUIS Prediction Account $tenantId..." -NoNewline
        $luis = New-AzCognitiveServicesAccount -ResourceGroupName $resourceGroup -Name $tenantId `
            -Type LUIS -SkuName "S0" -Location $luisAuthLocation -ErrorAction Stop
        $luisKey = Get-AzCognitiveServicesAccountKey -ResourceGroupName $resourceGroup -Name $tenantId                
        Write-Host "Done $($luis.AccountName) Key: $($luisKey.Key1)" -ForegroundColor Green
    
        Write-Host "Creating Application Insights $tenantId..." -NoNewline
        $appInsights = New-AzApplicationInsights -ResourceGroupName $resourceGroup -Name $tenantId -Location $ds_location -ErrorAction Stop
        Write-Host "Done $($appInsights.Name)" -ForegroundColor Green
    }

    Write-Host "Creating SaaS Marketplace offering $offerId..." -NoNewline
    $marketplaceApp = New-HbsSaaSApplication -ResourceName $Name -planId $planId -offerId $offerId -SubscriptionId $subscriptionId
    Write-Host "Done $($marketplaceApp.name)" -ForegroundColor Green

    $saasSubscriptionId = Split-Path $marketplaceApp.id -Leaf
    Write-Host "Creating HBS Tenant $tenantId..." -NoNewline
    $saasTenant = New-HbsTenant -name $Name -tenantId $tenantId `
        -saasSubscriptionId $saasSubscriptionId `
        -planId $planId -offerId $offerId `
        -location $location `
        -instrumentationKey $appInsights.InstrumentationKey
    Write-Host "Done" -ForegroundColor Green

    Write-Host "Importing LUIS Application from $luisAppFile..." -NoNewline
    $luisJSON = Get-Content -Raw -Path $luisAppFile
    $luisApplicationId = Import-LuisApplication -luisJSON $luisJSON -location $luisAuthLocation -authKey $luisAuthoringKey.Key1
    Write-Host "Done" -ForegroundColor Green

    Write-Host "Assigning LUIS app to LUIS account..." -NoNewline
    $assignLuisApp = Set-LuisApplicationAccount -appId $luisApplicationId -subscriptionId $subscriptionId `
                        -resourceGroup $resourceGroup -accountName $tenantId -location $luisAuthLocation -authKey $luisAuthoringKey.Key1
    Write-Host "Done" -ForegroundColor Green

    # Write-Host "Creating MS Graph API Service principle $tenantId-graph-sp..." -NoNewline
    # $spApp = New-HbsADApplication -displayName $tenantId-graph-sp 
    #                               # -applicationPermissions "Directory.Read.All Group.Read.All OnlineMeetings.ReadWrite.All"
    # Write-Host "Done" -ForegroundColor Green

    Write-Host "Importing template from $restorePath..." -NoNewline
    $restoreJSON = Get-Content -Raw -Path $restorePath
    # $restoreJSON = $restoreJSON.Replace("{clientId}", $spApp.app.AppId)
    # $restoreJSON = $restoreJSON.Replace("{clientSecret}", $spApp.creds.Value)
    # $restoreJSON = $restoreJSON.Replace("{tenantId}", (Get-AzureADTenantDetail).ObjectId)
    $saasTenant = Restore-HbsTenant -location $location -tenant $saasTenant -data $restoreJSON -saasSubscriptionId $saasSubscriptionId
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
