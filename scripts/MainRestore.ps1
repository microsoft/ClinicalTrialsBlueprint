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

# debug: print env varibles
# Get-ChildItem Env:

# get path
# $ScriptPath = Split-Path $MyInvocation.InvocationName

# restore language understanding model
Invoke-Expression "./RestoreLanguageUnderstanding.ps1 -cuiEndpoint $cuiEndpoint -cuiKey $cuiKey -fileLocation $fileLocation"

# restore bot
Invoke-Expression  "./RestoreBot.ps1 -botEndpoint $botEndpoint -botSecret $botSecret -fileLocation $fileLocation"
