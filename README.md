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
$fhirRg = New-AzResourceGroup -Name <fhir server group name> -Location eastus
```
Assign Fhir Server Name
```PowerShell
$fhirServerName = "<fhir server name>"
```

Create the Fhir server deployment. You will to provide a admin password for the SQL server

```PowerShell
New-AzResourceGroupDeployment -ResourceGroupName $fhirRg.ResourceGroupName -TemplateFile .\arm-templates\azuredeploy-fhir.json -serviceName $fhirServerName
```

Scale-up the Fhir Server database
```Powershell
$database = Set-AzSqlDatabase -ResourceGroupName $fhirRg.ResourceGroupName  -ServerName $fhirServerName -DatabaseName FHIR -Edition "Standard" -RequestedServiceObjectiveName "S1"  
```

Verify that the FHIR Server is running

```PowerShell
$metadataUrl = "https://$fhirServerName.azurewebsites.net/metadata" 
$metadata = Invoke-WebRequest -Uri $metadataUrl
$metadata.RawContent
```
It will take a minute or so for the server to respond the first time.

### Setup the Matching service
Create Resource Group that will contain all the resources required for the blueprint resources

```PowerShell
$rg = New-AzResourceGroup -Name <service Name> -Location eastus
```

Create a service principal. It will enable the matching services a programmatic access to the Key Vault

```Powershell
$sp = New-AzADServicePrincipal -DisplayName <service principal name>
```

Assign a name for the matching service
```Powershell
$ctmServiceName = "<ctm matching service>"
```
Assign the password of the Docker Container Registry
```Powershell
$acrPassword = ConvertTo-SecureString  -AsPlainText <acr password>
```

Create Clinical Trials Matching service Azure resources
```Powershell
$matchingOutput = New-AzResourceGroupDeployment -TemplateFile .\arm-templates\azuredeploy-ctm.json -ResourceGroupName $rg.ResourceGroupName -serviceName $ctmServiceName  -fhirServerName $fhirServerName -servicePrincipalObjectId $sp.Id -servicePrincipleClientId $sp.ApplicationId -servicePrincipalClientSecret $sp.secret -acrPassword $acrPassword
```

Check that the TextAnalytics for Healthcare service is running and ready
```powershell
$taReadyUrl = "https://$ctmServiceName-ayalon-webapp.azurewebsites.net/ready"
$taReadyResponse = Invoke-WebRequest -Uri $taReadyUrl
$taReadyResponse.RawContent
```

Check that the Query Engine Service is running
```powershell
$queryUrl = "https://$ctmServiceName-ctm-qe-webapp.azurewebsites.net/"
$queryResponse = Invoke-WebRequest -Uri $queryUrl
$queryResponse.RawContent
```

Check that the Disqualification Engine Service is running
```powershell
$disqualificationUrl = "https://$ctmServiceName-ctm-disq-webapp.azurewebsites.net/"
$disqualificationResponse = Invoke-WebRequest -Uri $disqualificationUrl
$disqualificationResponse.RawContent
```

Check that the Dynamic Criteria Selection Service is running and ready

```powershell
$dynamicCriteriaSelectionUrl = "https://$ctmServiceName-ctm-disq-webapp.azurewebsites.net/"
$dynamicCriteriaSelectionUrlResponse = Invoke-WebRequest -Uri $dynamicCriteriaSelectionUrl
$dynamicCriteriaSelectionUrlResponse.RawContent
```

### Setup the Healthcare Bot Service
Assign the Healthcare Bot service name 
```Powershell
$botServiceName = "<healthcare bot service>"
```

Load the marketplace script
```powershell
. .\scripts\marketplace.ps1
```

Create the Healthcare Bot Azure Marketplace SaaS Application
```powershell
$saasSubscriptionId =  New-HbsSaaSApplication -name $botServiceName -planId free
```

You can also see all your existing SaaS applications by running this command. 
```powershell
Get-HbsSaaSApplication
```

Deploy Healthcare Bot resources for the Marketplace SaaS application you just created or already had before.

```powershell
.\scripts\azuredeploy-healthcarebot.ps1 -ResourceGroup $rg.ResourceGroupName -saasSubscriptionId $saasSubscriptionId  -serviceName $botServiceName -botLocation US -matchingParameters $matchingOutput.Outputs
```
This command can take few minutes to complete

### Setup PostgreSQL Server
Install the PostgreSQL tools from [here](https://www.postgresql.org/download/windows/)

Download as static copy of the AACT from [here](https://aact.ctti-clinicaltrials.org/snapshots) an

Restore the DB from the dump file with pg_restore utility
```powershell
.\pg_restore --clean --host $ctmServiceName-ctm-postgresql.postgres.database.azure.com --port 5432 --username "<username>@$ctmServiceName-ctm-postgresql" --no-owner --dbname "ctdb" --verbose "<dmpfile>"
```