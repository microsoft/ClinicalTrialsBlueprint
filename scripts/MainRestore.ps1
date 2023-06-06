param (
    [Parameter(Mandatory = $true)]
    [string]$fileLocation
)


# get path
# $ScriptPath = Split-Path $MyInvocation.InvocationName

# restore language understanding model
Invoke-Expression "./scripts/RestoreLanguageUnderstanding.ps1 -fileLocation $fileLocation"

# restore bot
Invoke-Expression  "./scripts/RestoreBot.ps1 -fileLocation $fileLocation"
