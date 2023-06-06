param (
    [Parameter(Mandatory = $true)]
    [string]$fileLocation
)

# debug: print env varibles
Get-ChildItem Env:

$cuiKey = $env:CLU_KEY
$cuiEndpoint = $env:CLU_ENDPOINT


# Import the file into a new Cognitive Language Understanding project named "clinical_trial_metadata"
$projectName = "clinical_trial_metadata"
$modelLabel = 'clinical_trial_metadata'
$apiVersion = '?api-version=2022-10-01-preview'

$contentType = 'application/json; charset=UTF-8'
$headers = @{
    "Ocp-Apim-Subscription-Key" = $cuiKey
    "Content-Type"              = $contentType
    "Accept-Charset"            = 'UTF-8'
}

function WaitForJob {
    param (
        [Parameter(Mandatory = $true)]
        [string]$StatusEndpoint
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


function Call-Http {
    param (
        [Parameter(Mandatory = $false)]
        [string]$Method,
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        [Parameter(Mandatory = $false)]
        [string]$Body
    )

    try {
        
        Write-Warning "Calling $Method $Uri with body length $($Body.Length)"
        if ($Body) {
            $response = Invoke-WebRequest -Method $Method -Uri $Uri -Headers $headers -Body $Body -ErrorAction Stop -ContentType $contentType
        }
        else {
            $response = Invoke-WebRequest -Method $Method -Uri $Uri -Headers $headers -ErrorAction Stop -ContentType $contentType
        }
        return $response
    }
    catch {
        Write-Host "HTTP request failed with the following response:"
        Write-Host $_.Exception
        if (Write-Host $_.Exception.Response -ne $null) {
            Write-Host $_.Exception.Response.StatusCode.value__ 
            Write-Host $_.Exception.Response.StatusDescription
            $result = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($result)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd();
            Write-Host $responseBody
        }
        throw
    }
}


# Fetch json file from web address
$jsonFile = Invoke-WebRequest  -Method Get -Uri  "$fileLocation/clu/clinical_trial_metadata.json" -ContentType $contentType

# Send the request to import the project
$bodyJson = $jsonFile.Content

$importUri = $cuiEndpoint + "language/authoring/analyze-conversations/projects/$projectName/:import" + $apiVersion
$importResponse = Call-Http -Method Post `
    -Uri $importUri `
    -Body $bodyJson

$importLocation = $importResponse.Headers['operation-location'][0]
WaitForJob -StatusEndpoint $importLocation

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
} | ConvertTo-Json -Depth 4

$trainResponse = Call-Http -Method Post `
    -Uri $trainUri `
    -Body $bodyJson

Write-Warning "Train status: $($trainResponse.Content)"
$trainLocation = $trainResponse.Headers['operation-location'][0]
WaitForJob -StatusEndpoint $trainLocation

# Deploy the project
$deployUri = $cuiEndpoint + "language/authoring/analyze-conversations/projects/$projectName/deployments/deploy" + $apiVersion
$bodyJson = @{
    'trainedModelLabel' = $modelLabel
} | ConvertTo-Json -Depth 4

$deployResponse = Call-Http -Method Put `
    -Uri $deployUri `
    -Body $bodyJson

Write-Warning "Deploy status: $($deployResponse.Content)"
$deployLocation = $deployResponse.Headers['operation-location'][0]
WaitForJob -StatusEndpoint $deployLocation