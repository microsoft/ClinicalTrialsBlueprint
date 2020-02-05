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
* [Install Azure AD Module](https://docs.microsoft.com/en-us/powershell/azure/active-directory/install-adv2?view=azureadps-2.0#installing-the-azure-ad-module)


## Connect to Azure
```powershell
Login-AzAccount
```

## Connect to AzureAD
```powershell
Connect-AzureAD
```
## Create Healthcare Bot Marketplace SaaS Subscription

Switch to the scripts folder and create a SaaS application subscription. This will create the [Healthcare Bot application](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/microsoft-hcb.microsofthealthcarebot)
```powershell
$serviceName = "myService"
$saasSubscriptionId = marketplace -name $serviceName -plandId free
```

## Deploy required resources on your Azure Subscription

Create resource group
```powershell
$rg = New-AzResourceGroup -Name $serviceName -Location eastus
```

Now we will deploy all the required Azure resources and configure them. This includes confguring the Healthcare Bot and subscribing the SaaS application created before.

```powershell
default_azuredeploy.ps1 -saasSubscriptionId $saasSubscriptionId  -serviceName $serviceName
```
This command can take few minutes to complete.