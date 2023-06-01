param (
    [Parameter(Mandatory = $true)]
    [string]$botEndpoint, 
    [Parameter(Mandatory = $true)]
    [string]$botSecret,
    [Parameter(Mandatory = $true)]
    [string]$cuiEndpoint, 
    [Parameter(Mandatory = $true)]
    [string]$cuiKey,
    [Parameter(Mandatory = $true)]
    [string]$fileLocation
)

./restoreBot.ps1 -botEndpoint $botEndpoint -botSecret $botSecret -fileLocation $fileLocation
./restoreLanguageUnderstanding.ps1 -cuiEndpoint $cuiEndpoint -cuiKey $cuiKey -fileLocation $fileLocation
