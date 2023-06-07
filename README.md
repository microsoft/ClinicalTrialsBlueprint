

# Health Insights Clinical Trials Matching Service Healthbot Sample

## Description

This repository contains the ARM template and scripts to deploy a [Clinical Trials Matching Bot](https://learn.microsoft.com/en-us/azure/azure-health-insights/trial-matcher/overview#azure-health-bot-integration).

The Trial Matcher is an AI model offered within the context of the broader Project Health Insights. Trial Matcher is designed to match patients to potentially suitable clinical trials or find a group of potentially eligible patients to a list of clinical trials. [Read more about Azure Trial Matcher](https://learn.microsoft.com/en-us/azure/azure-health-insights/trial-matcher/overview)
In this blueprint, you will generate Azure Health Bot with built-in Clinical Trial Matching integration, enable to match a patient to set of clinical trials this patient is eligible for.

The resources that will be deployed with this template, to be used by the bot:
- [Azure Health bot](https://learn.microsoft.com/en-us/azure/health-bot/)
- [Azure Language Understanding](https://learn.microsoft.com/en-us/azure/cognitive-services/language-service/conversational-language-understanding/overview)
- [Azure Health Insight](https://learn.microsoft.com/en-us/azure/azure-health-insights/overview)

Additionally, during the deployment, the following resource will be created and will be auto-removed after the deployment finishes successfully:
- DeploymentScripts Resource (https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-script-template) - Used during the deployment
- [Azure Container Instance](https://azure.microsoft.com/en-us/products/container-instances/)
- [Azure Storage](https://learn.microsoft.com/en-us/azure/storage/common/storage-introduction)

## One-Click Deployment

### Requirements

- Azure subscription with write permission

To deploy a new bot directly in Azure, you can use this button:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmicrosoft%2FClinicalTrialsBlueprint%2Fgh-pages%2Fmain.json)

## Bot Usage

After successful deployment, to see the bot in action, open the generated bot resource, enter the management portal, and start a chat conversation with a prompt:

`clinical trials in israel for 24-year-old women with lung cancer`

The bot will use Azure Language Understanding (CLU) to recognize the intent "find clinical trials" and collect trial metadata:
- patient age
- patient sex
- patient condition
- wanted trial location

If any metadata wasn't provided or wasn't recognized, the bot will collect it separately.

After receiving the needed data, the bot will send a matching request to Azure Trial Matching, receive a trials list, and use the response to start asking relevant questions about the patient's condition to help Azure Trial Matching qualify the most relevant trials.

After a number of questions, the user will be provided with a list of clinical trials that are relevant to the provided metadata.

For additional health bot usage details, see [Azure Health Bot Documentation](https://learn.microsoft.com/en-us/azure/health-bot/)

## Manual Deployment

To deploy the ARM template manually, you can use the following instructions. The created resources will be the same as the resources created in the "One-Click Deployment" method.

### Requirements

- [Install Azure PowerShell](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-powershell#prerequisites)
- [Install the Azure PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps)
- [Install the Azure Bicep module](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#install-manually)

### Connect to Azure Subscription

### Requirements

- [Install Azure PowerShell](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-powershell#prerequisites)
- [Install the Azure PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps)
- [Install the Azure Bicep module](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#install-manually)

### Connect to Azure Subscription

### Connect to Azure Subscription
```PowerShell
Login-AzAccount
$account
 = Set-AzContext -Subscription <Your Subscription Name>
```
### Create Resource Group
Create Resource Group that will contain all the resources required for the blueprint resources
```PowerShell
$ctmRg = New-AzResourceGroup -Name <resources group name> -Location <region>
```

### Run Deployment
New-AzResourceGroupDeployment -ResourceGroupName $ctmRg -TemplateFile .\arm-templates\main.bicep
