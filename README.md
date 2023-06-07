# Health Insights Clinical Trials Matching Service Healthbot Blueprint

## Description
This Repo contains the ARM template and scripts to deploy A Clinical Trials Matching Bot.

The Trial Matcher is an AI model, offered within the context of the broader Project Health Insights. Trial Matcher is designed to match patients to potentially suitable clinical trials or find a group of potentially eligible patients to a list of clinical trials.
[Read more about Azure Trial Matcher](https://learn.microsoft.com/en-us/azure/azure-health-insights/trial-matcher/overview)

The resources that will be deploied with this template, to be used by the bot:
- [Azure Health bot](https://learn.microsoft.com/en-us/azure/health-bot/)
- [Azure Language Understanding](https://learn.microsoft.com/en-us/azure/cognitive-services/language-service/conversational-language-understanding/overview)
- [Azure Health Insight](https://learn.microsoft.com/en-us/azure/azure-health-insights/overview)

Additionely, during the deplyment the following resource will be created, and will be auto removed after the deployment finish succefully:
- DeploymentScripts Resource (https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-script-template) - Used during the deployment, 
- [Azure Container Instance](https://azure.microsoft.com/en-us/products/container-instances/)
- [Azure Storage]([https://azure.microsoft.com/en-us/free/storage/search/?ef_id=_k_CjwKCAjw1YCkBhAOEiwA5aN4ATfidi5l_Q2x3FkyTR1o3c6EY2fNRSMb_fuSDYnFnws0oHlYtsDdKBoCgLsQAvD_BwE_k_&OCID=AIDcmm81syc84i_SEM__k_CjwKCAjw1YCkBhAOEiwA5aN4ATfidi5l_Q2x3FkyTR1o3c6EY2fNRSMb_fuSDYnFnws0oHlYtsDdKBoCgLsQAvD_BwE_k_&gclid=CjwKCAjw1YCkBhAOEiwA5aN4ATfidi5l_Q2x3FkyTR1o3c6EY2fNRSMb_fuSDYnFnws0oHlYtsDdKBoCgLsQAvD_BwE](https://learn.microsoft.com/en-us/azure/storage/common/storage-introduction))


## One Click Deployemnt
To Deploy a new bot directly in azure, you can use this button
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmicrosoft%2FClinicalTrialsBlueprint%2Fgh-pages%2Fmain.json)

## Bot Useage
After succesfull deployment, to see the bot in action, open the generated bot resource, enter the managment portal, and start a chat conversation with a prompt
`clinical trials in israel for 24 years old women with lang cancer`
The bot will use azure Language Understanding (CLU) to recognize the intent "find clinical trilas",
and collect trial metadata:
- patient age
- pateint sex
- patient condition
- wanted trial location
If any metadata wasn't provided or wasn't recognized, the bot will collect it seperatly.
After reciving the needed datam the bot will send a matching request to Azure Trial Matching,

[Azure Health Bot Documentation](https://learn.microsoft.com/en-us/azure/health-bot/)



## Manual Deployemnt

### Requirments
[Install Azure powershell] (https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-powershell#prerequisites)
[Install the Azure PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps)
[Install the Azure Biucep module](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#install-manually)

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
