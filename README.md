---
page_type: sample
languages:
- csharp
products:
- dotnet
description: "Add 150 character max description"
urlFragment: "update-this-to-unique-url-stub"
---

# Clinical Trials Matching Service Blueprint


## Requirements
* Clone/Download this repository to you local drive
* [Install the Azure PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-3.3.0)


## Connect to Azure Subscription
```PowerShell
Login-AzAccount

Set-AzContext -Subscription <Your Subscription Name>
```

## FHIR Server
Create a Resource group for the Fhir server

```PowerShell
$fhirRg = New-AzResourceGroup -Name ctm-fhir-blueprint -Location eastus
```
Assign Fhir Server Name
```PowerShell
$fhirServiceName = <fhir service name>
```

Create the Fhir server deployment. You will to provide a admin password for the SQL server
```PowerShell
New-AzResourceGroupDeployment -ResourceGroupName $fhirRg.ResourceGroupName -TemplateFile ..\arm-templates\azuredeploy-fhir.json -serviceName $fhirServiceName
```

Verify that the Fhir Server is running
```PowerShell
$metadataUrl = "https://$fhirServiceName.azurewebsites.net/metadata" 
$metadata = Invoke-WebRequest -Uri $metadataUrl
$metadata.RawContent
```
It will take a minute or so for the server to respond the first time.

Create Resource Group for the Clinical Trials Blueprint resources

```PowerShell
$rg = New-AzResourceGroup -Name ctm-blueprint -Location eastus
```

Create the TextAnalytics for Healthcare deployment
```PowerShell
$taServiceName = <text analytics service>
New-AzResourceGroupDeployment -TemplateFile ..\arm-templates\azuredeploy-ta4h.json -ResourceGroupName $rg.ResourceGroupName -serviceName $taServiceName
```

Check Text Analytics for Healthcare service is running
```Powershell
$statusUrl = "https://$taServiceName-webapp.azurewebsites.net/status"
$status = Invoke-WebRequest -Uri $statusUrl
$status.RawContent
```
It will take about 20 minutes for the service to deploy and run

Create Structuring Service
```Powershell
$structuringServiceName = <ctm structuring service>
New-AzResourceGroupDeployment -TemplateFile ..\arm-templates\azuredeploy-structuring.json -ResourceGroupName $rg.ResourceGroupName -serviceName $structuringServiceName
```


### Create Healthcare Bot

Create the Healthcare Bot SaaS Application
```powershell
$botServiceName = "myService"
$saasSubscriptionId = .\marketplace -name $botServiceName -plandId free
```

Now we will deploy all the required Azure resources and configure them. This includes confguring the Healthcare Bot and subscribing the SaaS application created before.

```powershell
.\default_azuredeploy.ps1 -saasSubscriptionId $saasSubscriptionId  -serviceName $botServiceName
```
This command can take few minutes to complete.