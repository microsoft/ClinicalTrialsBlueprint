param(
    [Parameter(Mandatory=$true)]
    $saasSubscriptionId,
    [Parameter(Mandatory=$true)]
    [String]
    $serviceName,
    [Parameter(Mandatory=$true)]
    [ValidateSet("US","EU")]
    $botLocation,
    [Parameter(Mandatory=$true)]
    $ResourceGroup
)

. ./profile.ps1
. ./luis.ps1
. ./tenant.ps1

$context = Get-AzContext
$subscriptionId = $context.subscription.id
$luisAuthLocation = "westus" # Authoring location is only in West US

$env="-dev"
$portalEndpoint = "https://us.healthbot$env.microsoft.com/account"

$luisPath = "../lu"
$restorePath = "../bot-templates"

Try {
    Write-Host "Running Template Deployment..."
    $output = New-AzResourceGroupDeployment -serviceName $serviceName `
                                            -ResourceGroupName $ResourceGroup  `
                                            -saasSubscriptionId $saasSubscriptionId `
                                            -TemplateFile "../arm-templates/azuredeploy-healthcarebot.json"                                             

    $output
    
    $tenantId = $output.Outputs["serviceUniqueName"].Value    

    Write-Host "Creating Healthcare Bot Tenant $tenantId..." -NoNewline
    $saasTenant = New-HbsTenant -name $serviceName -tenantId $tenantId `
                                -saasSubscriptionId $saasSubscriptionId `
                                -location $botLocation `
                                -instrumentationKey $output.Outputs["instrumentationKey"].Value
    $saasTenant

    # Uploads all the LUIS files. Each file is a luis application
    $luisApplications = @{}
    Get-ChildItem -Path $luisPath | ForEach-Object {
        Write-Host "Get LUI Application '"$_.BaseName "'..." -NoNewline       
        $luisApplication = Get-LuisApplicationByName -appName $_.BaseName -location $luisAuthLocation `
                                                     -authKey $output.Outputs["luisAuthotingKey"].Value
        if ($null -eq $luisApplication) {    
            Write-Host "Not found - Importing LUIS Application from " $_.BaseName "..." -NoNewline
            $luisJSON = Get-Content -Raw -Path $_.FullName
            $luisApplicationId = Import-LuisApplication -appName $_.BaseName -luisJSON $luisJSON -location $luisAuthLocation  `
                                                        -authKey $output.Outputs["luisAuthotingKey"].Value
            Write-Host "Done" -ForegroundColor Green
        } else {
            $luisApplicationId = $luisApplication.id
            Write-Host "Done" -ForegroundColor Green
        }                                                    
        $luisApplications[$_.BaseName] = $luisApplicationId
        
        Write-Host "Assigning LUIS app " $_.BaseName " to LUIS account..." -NoNewline
        $assignLuisApp = Set-LuisApplicationAccount -appId $luisApplicationId -subscriptionId $subscriptionId `
                            -resourceGroup $ResourceGroup -accountName $serviceName"-prediction" `
                            -location $luisAuthLocation -authKey $output.Outputs["luisAuthotingKey"].Value
        Write-Host "Done" -ForegroundColor Green
    }

    # Restore all the hbs templates
    Get-ChildItem -Path $restorePath | ForEach-Object {
        Write-Host "Importing template from " $_.BaseName "..." -NoNewline
        $restoreJSON = Get-Content -Raw -Path $_.FullName
        
        # Here you need to replace the place holders with real data

        $saasTenant = Restore-HbsTenant -location $botLocation -tenant $saasTenant `
                                        -data $restoreJSON -saasSubscriptionId $saasSubscriptionId
        Write-Host "Done" -ForegroundColor Green
    }

    $webchatSecret = $saasTenant.webchat_secret

    Write-Host "Your Healthcare Bot is now ready! You can access various resources below:" -ForegroundColor Green
    Write-Host " - Management Portal: " $portalEndpoint/$tenantId -ForegroundColor Green
    Write-Host " - Marketplace SaaS Application: https://ms.portal.azure.com/#@/resource/providers/Microsoft.SaaS/saasresources/$saasSubscriptionId/overview" -ForegroundColor Green
    Write-Host " - WebChat Client: https://hatenantstorageprod.blob.core.windows.net/public-websites/webchat/index.html?s=$webchatSecret" -ForegroundColor Green

}    
Catch {
    Write-Host
    Write-Error -Exception $_.Exception 
    Write-Error -Exception $_.ErrorDetails.Message   
}    
