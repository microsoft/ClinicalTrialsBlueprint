

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

There are two modes to use this blueprint: One-Click Deployment or Manual Deployment. 
In both modes you will create the same Azure resources. One-Click-Deployment is the simplest way to start with. When using the Manual Deployment, you receive the experience of step-by-step process. 

## One-Click Deployment

### Requirements
- Azure subscription with 'write' permission
To deploy a new bot directly in Azure, you can use this button:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmicrosoft%2FClinicalTrialsBlueprint%2Fgh-pages%2Fmain.json)

## Manual Deployment
<details><summary>To deploy the ARM template manually, you can use the following instructions. The created resources will be the same as the resources created in the "One-Click Deployment" method.</summary>



### Requirements
- [Install Azure PowerShell](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-powershell#prerequisites)
- [Install the Azure PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps)
- [Install the Azure Bicep module](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#install-manually)

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
```PowerShell
New-AzResourceGroupDeployment -ResourceGroupName $ctmRg -TemplateFile .\arm-templates\main.bicep
```

</details>

## How to use the Azure Health Bot with built-in Clinical Trial Matching
After successful deployment, to see the bot in action, open the generated bot resource, enter the management portal, and start a chat conversation with a prompt,
for example:
`clinical trials in israel for 24-year-old women with lung cancer`
or
`find clinical trials for Alzheimer's disease`
The bot will use Azure Language Understanding (CLU) to recognize the intent "find clinical trials", and analyze from this statement the relevant clinical trial characteristics to look for. The data provided by the user in this case includes patient age, patient sex, patient condition and preferred trial location.

To improve the patient qualification, additional information can be captured from the patient, by generating a question and waiting for user input.  After receiving the needed data, the bot will send a matching request to the Trial Matching, receive a trials list, and use the response to start asking additional questions about the patient's condition to enable Trial Matching perform a more accurate qualification of the eligible clinical trials. After a number of questions, the user will be provided with a list of clinical trials that are relevant to the provided clinical data and preference data.

After receiving the needed data, the bot will send a matching request to Azure Trial Matching, receive a trials list, and use the response to start asking relevant questions about the patient's condition to help Azure Trial Matching qualify the most relevant trials.

![image](https://github.com/microsoft/ClinicalTrialsBlueprint/assets/12156855/796ab1d5-0834-4dfd-b005-55bbd8ec90e6)

For additional health bot usage details, see [Azure Health Bot Documentation](https://learn.microsoft.com/en-us/azure/health-bot/)

