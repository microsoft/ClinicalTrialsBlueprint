# Clinical Trials Matching Service Blueprint

## Requirements

Clone this repository to your local drive

```Powershell
git clone https://github.com/microsoft/ClinicalTrialsBlueprint
cd ClinicalTrialsBlueprint
```

[Install the Azure PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-3.3.0)

## Connect to Azure Subscription

```PowerShell
Login-AzAccount
$account = Set-AzContext -Subscription <Your Subscription Name>
```

## Setup the FHIR Server

Create a Resource group for the FHIR server. It must be in a separate resource group from other resources in the blueprint becuase we are creating a Windows service plan

```PowerShell
$fhirRg = New-AzResourceGroup -Name <fhir server group name> -Location eastus
```

Assign Fhir Server Name

```PowerShell
$fhirServerName = "<fhir server name>"
```

Create the FHIR server deployment. You will to provide a admin password for the SQL server

```PowerShell
New-AzResourceGroupDeployment -ResourceGroupName $fhirRg.ResourceGroupName `
                              -TemplateFile .\arm-templates\azuredeploy-fhir.json `
                              -serviceName $fhirServerName
```

Scale-up the Fhir Server database

```Powershell
$database = Set-AzSqlDatabase -ResourceGroupName $fhirRg.ResourceGroupName  `
                              -ServerName $fhirServerName -DatabaseName FHIR -Edition "Standard" `
                              -RequestedServiceObjectiveName "S1"  
```

Verify that the FHIR Server is running

```PowerShell
$metadataUrl = "https://$fhirServerName.azurewebsites.net/metadata" 
$metadata = Invoke-WebRequest -Uri $metadataUrl
$metadata.RawContent
```

It will take a minute or so for the server to respond the first time.

## Setup the Matching service

Create Resource Group that will contain all the resources required for the blueprint resources

```PowerShell
$rg = New-AzResourceGroup -Name <service Name> -Location eastus
```

Assign a name for the matching service

```Powershell
$ctmServiceName = "<ctm matching service>"
```

Assign the password of the Docker Container Registry

```Powershell
$acrPassword = ConvertTo-SecureString  -AsPlainText <acr password>
```

Create Clinical Trials Matching service Azure resources

```Powershell
$matchingOutput = New-AzResourceGroupDeployment -TemplateFile .\arm-templates\azuredeploy-ctm.json `
                -ResourceGroupName $rg.ResourceGroupName -serviceName $ctmServiceName `
                -fhirServerName $fhirServerName -acrPassword $acrPassword
```

Check that the TextAnalytics for Healthcare service is running and ready

```powershell
$taReadyUrl = $matchingOutput.Outputs.gatewayEndpoint.Value + "/ta4h/ready"
$taReadyResponse = Invoke-WebRequest -Uri $taReadyUrl
$taReadyResponse.RawContent
```

Check that the Query Engine Service is running

```powershell
$queryUrl = $matchingOutput.Outputs.gatewayEndpoint.Value + "/qe"
$queryResponse = Invoke-WebRequest -Uri $queryUrl
$queryResponse.RawContent
```

Check that the Disqualification Engine Service is running

```powershell
$disqualificationUrl = $matchingOutput.Outputs.gatewayEndpoint.Value + "/disq"
$disqualificationResponse = Invoke-WebRequest -Uri $disqualificationUrl
$disqualificationResponse.RawContent
```

Check that the Dynamic Criteria Selection Service is running and ready

```powershell
$dynamicCriteriaSelectionUrl = $matchingOutput.Outputs.gatewayEndpoint.Value + "/dcs"
$dynamicCriteriaSelectionUrlResponse = Invoke-WebRequest -Uri $dynamicCriteriaSelectionUrl
$dynamicCriteriaSelectionUrlResponse.RawContent
```

### Restrict Access to service

```Powershell
. .\scripts\restrictAccess.ps1
```

```powershell
Add-HbsRestrictIPs -resourceGroupName $rg.ResourceGroupName -serviceName $ctmServiceName `
                   -fhirResoureGroupName ctm-fhir-blueprint -fhirServiceName $fhirServerName
```

### Setup the Healthcare Bot Service

Assign the Healthcare Bot service name 

```Powershell
$botServiceName = "<healthcare bot service>"
```

Load the marketplace script

```powershell
. .\scripts\marketplace.ps1
```

Create the Healthcare Bot Azure Marketplace SaaS Application

```powershell
$saasSubscriptionId =  New-HbsSaaSApplication -name $botServiceName -planId free
```

You can also see all your existing SaaS applications by running this command. 

```powershell
Get-HbsSaaSApplication
```

Deploy Healthcare Bot resources for the Marketplace SaaS application you just created or already had before.

```powershell
.\scripts\azuredeploy-healthcarebot.ps1 -ResourceGroup $rg.ResourceGroupName `
                    -saasSubscriptionId $saasSubscriptionId  -serviceName $botServiceName `
                    -botLocation US -matchingParameters $matchingOutput.Outputs -restoreCtti restoreCttiDb
```

This command can take few minutes to complete
