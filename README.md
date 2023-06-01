# Clinical Trials Matching Service Blueprint
az group create --name yochai-rg-test -l eastus
az deployment group create --resource-group yochai-rg-test --template-file .\arm-templates\azuredeploy-ctm.json
az bicep build --file .\arm-templates\main.bicep

## One click deployemnt
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://github.com/microsoft/ClinicalTrialsBlueprint/releases/download/master/main.json)


## One click deployemnt
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