param (
    [Parameter(Mandatory = $true)]
    [string]$fileLocation
)


# debug: print env varibles
# Get-ChildItem Env:

# restore language understanding model
Invoke-Expression "./RestoreLanguageUnderstanding.ps1 -fileLocation $fileLocation"

# restore bot
Invoke-Expression  "./RestoreBot.ps1 -fileLocation $fileLocation"
