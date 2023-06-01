param (
    [Parameter(Mandatory=$true)]
    [string]$botKey,
    [Parameter(Mandatory=$true)]
    [string]$botEndpoint, 
    [Parameter(Mandatory=$true)]
    [string]$fileLocation
)

# Fetch json file from web address
$jsonFile = Invoke-WebRequest`
 -Uri $fileLocation + "/clu/metadata_clinical_trials.json"`
 -OutFile "file.json"

# Import the file into a new Cognitive Language Understanding project named "metadata_clinical_trials"
$projectName = "metadata_clinical_trials"
$apiVersion = "2022-05-01"

# Set the headers for the request
$headers = @{
    "Ocp-Apim-Subscription-Key" = $key
    "Content-Type" = "application/json"
}

# Send the request to import the project
$bodyJson = $jsonFile.Content
$importResponse = Invoke-WebRequest `
                    -Method Post `
                    -Uri "$endpoint/language/authoring/analyze-text/projects/$projectName/:import?api-version=$apiVersion"`
                    -Headers $headers -Body $bodyJson

Write-Information   "Import status: $($importResponse.Content)"

# Train the project
$trainResponse = Invoke-WebRequest  -Method Post
-Uri "$endpoint/language/authoring/analyze-text/projects/$projectName/train?api-version=$apiVersion" `
-Headers $headers

Write-Information "Train status: $($trainResponse.Content)"

# Deploy the project
$deployResponse = Invoke-WebRequest  -Method Post
-Uri "$endpoint/language/authoring/analyze-text/projects/$projectName/deploy?api-version=$apiVersion" `
-Headers $headers

Write-Information "Deploy status: $($deployResponse.Content)"