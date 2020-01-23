param(
    [Parameter(Mandatory=$true)]
    $saasSubscriptionId,
    [Parameter()]
    [String]
    $resourceGroup = "CTM-Blueprint",
    [Parameter()]
    [String]
    $serviceName = "CTM-Bot"
)

. ./profile.ps1
. ./utils.ps1
. ./luis.ps1
. ./bot.ps1
. ./tenant.ps1
. ./ad.ps1


$context = Get-AzContext
$userId = $context.Account.id
$subscriptionId = $context.subscription.id
$luisAuthLocation = "westus"
$env="-dev"
$portalEndpoint = "https://us.healthbot$env.microsoft.com/account"
$hbsLocation = "US"
$luisPath = "../lu"
$restorePath = "../bot-templates/teams-handoff.json"
$restorePath = "../bot-templates"

$objectId =$(Get-AzureADUser -Filter "UserPrincipalName eq '$userId'").ObjectId
Write-Host ObjectId: $objectId

Try {
    Write-Host "Running Template Deployment"
    $output = New-AzResourceGroupDeployment -serviceName $serviceName `
                                            -ResourceGroupName $resourceGroup  `
                                            -TemplateFile "../arm-templates/azuredeploy.json" `
                                            -objectId $objectId `

    $output
    
    $tenantId = $output.Outputs["serviceUniqueName"].Value

    Write-Host "Creating HBS Tenant $tenantId..." -NoNewline
    $saasTenant = New-HbsTenant -name $serviceName -tenantId $tenantId `
                                -saasSubscriptionId $saasSubscriptionId `
                                -location $hbsLocation `
                                -instrumentationKey $output.Outputs["instrumentationKey"].Value
    $saasTenant

    # Uploads all the LUIS files. Each file is a luis application
    $luisApplications = @{}
    Get-ChildItem -Path $luisPath | ForEach-Object {        
        $luisApplication = Get-LuisApplicationByName -appName $_.BaseName -location $luisAuthLocation `
                                                     -authKey $output.Outputs["luisAuthotingKey"].Value
        if ($null -eq $luisApplication) {    
            Write-Host "Importing LUIS Application from " $_.BaseName "..." -NoNewline
            $luisJSON = Get-Content -Raw -Path $_.FullName
            $luisApplicationId = Import-LuisApplication -appName $_.BaseName -luisJSON $luisJSON -location $luisAuthLocation  `
                                                        -authKey $output.Outputs["luisAuthotingKey"].Value
            Write-Host "Done" -ForegroundColor Green
        } else {
            $luisApplicationId = $luisApplication.id
        }                                                    
        $luisApplications[$_.BaseName] = $luisApplicationId
        
        Write-Host "Assigning LUIS app " $_.BaseName " to LUIS account..." -NoNewline
        $assignLuisApp = Set-LuisApplicationAccount -appId $luisApplicationId -subscriptionId $subscriptionId `
                            -resourceGroup $resourceGroup -accountName $tenantId"-prediction" -location $luisAuthLocation -authKey $output.Outputs["luisAuthotingKey"].Value
        Write-Host "Done" -ForegroundColor Green
    }

    # Restore all the hbs templates
    Get-ChildItem -Path $restorePath | ForEach-Object {
        Write-Host "Importing template from " $_.BaseName "..." -NoNewline
        $restoreJSON = Get-Content -Raw -Path $_.FullName
        
        # Here you need to replace the place holders with real data

        $saasTenant = Restore-HbsTenant -location $hbsLocation -tenant $saasTenant `
                                        -data $restoreJSON -saasSubscriptionId $saasSubscriptionId
        Write-Host "Done" -ForegroundColor Green
    }

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
