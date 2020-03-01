# Clinical Trials Matching Service Blueprint


### Requirements
Clone this repository to your local drive
```
git clone https://github.com/microsoft/ClinicalTrialsBlueprint
cd ClinicalTrialsBlueprint
```
[Install the Azure PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-3.3.0)


### Connect to Azure Subscription
```PowerShell
Login-AzAccount
$account = Set-AzContext -Subscription <Your Subscription Name>
```

### Setup the FHIR Server
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

### Setup the Matching service
Create Resource Group for the that will contain all the resources required for the blueprint

```PowerShell
$rg = New-AzResourceGroup -Name <service>-Matching -Location eastus
```

Create a service principal. It will enable the matching services a programmatic access to the Key Vault

```Powershell
$sp = New-AzADServicePrincipal -DisplayName <service principal name>
```

Assign a name for the matching service
```Powershell
$matchingServiceName = <ctm matching service>
```

Create Matching service Azure resources
```Powershell
$matchingOutput = New-AzResourceGroupDeployment -TemplateFile ..\arm-templates\azuredeploy-ctm.json -ResourceGroupName $rg.ResourceGroupName -serviceName $matchingServiceName  -servicePrincipalObjectId $sp.Id -servicePrincipleClientId $sp.ApplicationId -servicePrincipalClientSecret $sp.secret
```

Check that the TextAnalytics for Healthcare service is running
```powershell
$taUrl = "https://$matchingServiceName-ayalon-webapp.azurewebsites.net/status"
$taResponse = Invoke-WebRequest -Uri $taUrl
$taResponse.RawContent
```

Check that the Query Engine Service is running
```powershell
$queryEngineUrl = "https://$matchingServiceName-ctm-qe-webapp.azurewebsites.net/"
$queryEngineResponse = Invoke-WebRequest -Uri $queryEngineUrl
$queryEngineResponse.RawContent
```

Check that the Disqualification Engine Service is running
```powershell
$disqualificationEngineUrl = "https://$matchingServiceName-ctm-disq-webapp.azurewebsites.net/"
$disqualificationEngineResponse = Invoke-WebRequest -Uri $disqualificationEngineUrl
$disqualificationEngineResponse.RawContent
```

### Setup the Healthcare Bot Service
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

### Setup PostgreSQL Server
Install the PostgreSQL tools from [here](https://www.postgresql.org/download/windows/)

Download as static copy of the AACT from [here](https://aact.ctti-clinicaltrials.org/snapshots)


