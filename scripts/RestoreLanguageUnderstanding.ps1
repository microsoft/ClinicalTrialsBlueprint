param (
    [Parameter(Mandatory = $true)]
    [string]$fileLocation
)

$cuiKey = $env:CLU_KEY
$cuiEndpoint = $env:CLU_ENDPOINT


# Import the file into a new Cognitive Language Understanding project named "clinical_trial_metadata"
$projectName = "clinical_trial_metadata"
$modelLabel = 'clinical_trial_metadata'
$apiVersion = '?api-version=2022-10-01-preview'

# Set the headers for the request
$headers = @{
    "Ocp-Apim-Subscription-Key" = $cuiKey
    "Content-Type"              = "application/json"
}

function WaitForJob {
    param (
        [Parameter(Mandatory = $true)]
        [string]$statusEndpoint
    )
    Write-Warning "Waiting for job: $statusEndpoint"
    do {
        Start-Sleep -Seconds 5
        $statusResponse = Invoke-WebRequest -Method Get -Uri $statusEndpoint -Headers $headers
        $status = ($statusResponse.Content | ConvertFrom-Json).status
        Write-Host "Status: $status"
    } while ($status -match "notStarted|running")

    return $status
}





# Fetch json file from web address
$jsonFile = Invoke-WebRequest -Uri  "$fileLocation/clu/metadata_clinical_trials.json" 

# Send the request to import the project
$bodyJson = $jsonFile.Content
$importUri = $cuiEndpoint + "language/authoring/analyze-conversations/projects/$projectName/:import" + $apiVersion
Write-Warning "Importing file: $importUri"
$importResponse = Invoke-WebRequest -Method Post `
    -Uri $importUri `
    -Headers $headers -Body $bodyJson

WaitForJob $importResponse.Headers['operation-location']

Write-Warning   "Import status: $($importResponse.Content)"

# Train the project
$trainUri = $cuiEndpoint + "language/authoring/analyze-conversations/projects/$projectName/:train" + $apiVersion
$bodyJson = @{
    'modelLabel'            = $modelLabel
    'trainingMode'          = 'standard'
    'trainingConfigVersion' = 'latest'
    'evaluationOptions'     = @{
        'kind'                    = 'percentage'
        'testingSplitPercentage'  = 20
        'trainingSplitPercentage' = 80
    }
}

$trainResponse = Invoke-WebRequest -Method Post -Uri $trainUri -Headers $headers -Body $bodyJson

Write-Warning "Train status: $($trainResponse.Content)"
WaitForJob $importResponse.Headers['operation-location']

# Deploy the project
$deployUri = $cuiEndpoint + "language/authoring/analyze-conversations/projects/$projectName/deployments/deploy" + $apiVersion
$bodyJson = @{
    'trainedModelLabel' = $modelLabel
}

$deployResponse = Invoke-WebRequest -Method Put `
    -Uri $deployUri `
    -Headers $headers `
    -Body $bodyJson

Write-Warning "Deploy status: $($deployResponse.Content)"
WaitForJob $importResponse.Headers['operation-location']