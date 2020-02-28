# Clinical Trials Matching Service Blueprint


### Requirements
* Clone this repository to you local drive
```
git clone https://github.com/microsoft/ClinicalTrialsBlueprint
cd ClinicalTrialsBlueprint
```
* [Install the Azure PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-3.3.0)


### Connect to Azure Subscription
```PowerShell
Login-AzAccount
$account = Set-AzContext -Subscription <Your Subscription Name>
```

### FHIR Server
Create a Resource group for the FHIR server. It must be in a separate resource group from other resources in the blueprint becuase we are creating a Windows service plan

```PowerShell
$fhirRg = New-AzResourceGroup -Name <service>-Fhir -Location eastus
```
Assign Fhir Server Name
```PowerShell
$fhirServiceName = <fhir service name>
```

Create the Fhir server deployment. You will to provide a admin password for the SQL server

```PowerShell
New-AzResourceGroupDeployment -ResourceGroupName $fhirRg.ResourceGroupName -TemplateFile ..\arm-templates\azuredeploy-fhir.json -serviceName $fhirServiceName
```

Verify that the FHIR Server is running

```PowerShell
$metadataUrl = "https://$fhirServiceName.azurewebsites.net/metadata" 
$metadata = Invoke-WebRequest -Uri $metadataUrl
$metadata.RawContent
```
It will take a minute or so for the server to respond the first time.

### Matching and Bot resources
Create Resource Group for the that will contain all the resources required for the blueprint

```PowerShell
$rg = New-AzResourceGroup -Name <service>-Matching -Location eastus
```

### Matching Service

Create a service proncipal. We will need it to allow programtic access to Key Vault

```Powershell
$sp = New-AzADServicePrincipal -DisplayName <service principal name>
```

Assign strcuturing service name
```Powershell
$matchingServiceName = <ctm matching service>
```

Create Matching Service deployment
```Powershell
$matchingOutput = New-AzResourceGroupDeployment -TemplateFile ..\arm-templates\azuredeploy-matching.json -ResourceGroupName $rg.ResourceGroupName -serviceName $matchingServiceName  -servicePrincipalObjectId $sp.Id -servicePrincipleClientId $sp.ApplicationId -servicePrincipalClientSecret $sp.secret
```

### Healthcare Bot
Assign the Healthcare Bot service name 
```Powershell
$botServiceName = <healthcare bot service>
```
Create the Healthcare Bot SaaS Application
```powershell
$saasSubscriptionId = .\marketplace.ps1 -name $botServiceName -planId free
```

Deploy Healthcare Bot resources

```powershell
.\azuredeploy-healthcarebot.ps1 -ResourceGroup $rg.ResourceGroupName -saasSubscriptionId $saasSubscriptionId  -serviceName $botServiceName -botLocation US -matchingParameters $matchingOutput.Outputs
```
This command can take few minutes to complete.
