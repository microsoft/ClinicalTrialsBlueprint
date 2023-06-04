param (
    [Parameter(Mandatory=$true)]
    [string]$fileLocation
)

$cuiKey = $env:CLU_KEY
$cuiEndpoint = $env:CLU_ENDPOINT


# Import the file into a new Cognitive Language Understanding project named "metadata_clinical_trials"
$projectName = "metadata_clinical_trials"
$apiVersion = '?api-version=2022-10-01-preview'

# Set the headers for the request
$headers = @{
    "Ocp-Apim-Subscription-Key" = $cuiKey
    "Content-Type" = "application/json"
}

# Fetch json file from web address
$jsonFile = Invoke-WebRequest -Uri  "$fileLocation/clu/metadata_clinical_trials.json" 

# Send the request to import the project
$bodyJson = $jsonFile.Content
$importUri = $cuiEndpoint + "language/authoring/analyze-conversations/projects/$projectName/:import"+ $apiVersion
Write-Warning "Importing file: $importUri"
$importResponse = Invoke-WebRequest -Method Post `
                    -Uri $importUri `
                    -Headers $headers -Body $bodyJson

Write-Warning   "Import status: $($importResponse.Content)"

# Train the project
$trainUri = $cuiEndpoint + "language/authoring/analyze-conversations/projects/$projectName/train" + $apiVersion
$trainResponse = Invoke-WebRequest -Method Post -Uri $trainUri -Headers $headers

Write-Warning "Train status: $($trainResponse.Content)"

# Deploy the project
$deployUri = $cuiEndpoint + "language/authoring/analyze-conversations/projects/$projectName/deploy" + $apiVersion
$deployResponse = Invoke-WebRequest -Method Post `
                  -Uri $deployUri `
                  -Headers $headers

Write-Warning "Deploy status: $($deployResponse.Content)"
