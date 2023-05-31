param ($CLUsecret, $CLUbaseUrl)

Add-Type -AssemblyName System.Security

Function Get-HMACSHA512 {
    param(
        [Parameter(Mandatory = $true)][String]$data
        , [Parameter(Mandatory = $true)][String]$key
    )
    $hmacsha = New-Object System.Security.Cryptography.HMACSHA256  
    $hmacsha.key = [Text.Encoding]::UTF8.GetBytes($key)
    $bytesToSign = [Text.Encoding]::UTF8.GetBytes($data)
    $sign = $hmacsha.ComputeHash($bytesToSign)
    return $sign
}

$CLUTemplate = Invoke-WebRequest `
    -Uri "https://raw.githubusercontent.com/microsoft/ClinicalTrialsBlueprint/task/tolehman/migrate_to_health_insights_api/clu/metadata_clinical_trials.ps1" `
    -Method "get" 

# $botTemplateString = [System.Text.Encoding]::UTF8.GetString($botTemplate.Content)
$CLUTemplateString = $CLUTemplate.Content

$apiUrl = $CLUbaseUrl + "/language/authoring/analyze-text/projects/metadata_clinical_trials/:import?api-version=2022-05-01"

$headers = @{
    Authorization = 'Bearer ' + $jwtToken
}

Write-Warning "api url: $apiUrl."

Get-ChildItem Env:
# replace env varibles placeholders in template with its actual value by using ExpandEnvironmentVariables
# and convert to file
$CLUTemplateString = $CLUTemplateString.TrimEnd() | ForEach-Object { [Environment]::ExpandEnvironmentVariables($_) }

$body = @{
    hbs = $botTemplateString
} | ConvertTo-Json -Depth 10

$result = Invoke-WebRequest -Uri $apiUrl `
    -Method "post" `
    -Headers $headers `
    -ContentType "application/json; charset=utf-8" `
    -Body $body
    # -InFile "./temp.json" `

Write-Warning "bot template creation result: $result"