# Health Insights Clinical Trials Matching Service Healthbot Blueprint

## One click deployemnt
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fgithub.com%2Fmicrosoft%2FClinicalTrialsBlueprint%2Freleases%2Fdownload%2Fmaster%2Fmain.json)

### [Requirments](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-powershell#prerequisites)
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
$ctmRg = New-AzResourceGroup -Name <resources group name> -Location eastus
```

### Run Deployment
New-AzResourceGroupDeployment -ResourceGroupName $ctmRg -TemplateFile .\arm-templates\main.bicep