# Clinical Trials Matching Service Blueprint
az group create --name yochai-rg-test -l eastus
az deployment group create --resource-group yochai-rg-test --template-file .\arm-templates\azuredeploy-ctm.json
az bicep build --file .\arm-templates\main.bicep

## One click deployemnt
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://raw.githubusercontent.com/microsoft/ClinicalTrialsBlueprint/task/tolehman/migrate_to_health_insights_api/arm-templates.json)


## One click deployemnt
### Requirments
[Install the Azure PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps)

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
New-AzResourceGroupDeployment -ResourceGroupName $ctmRg -TemplateFile .\arm-templates\main.json