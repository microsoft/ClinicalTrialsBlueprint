param (
    [Parameter(Mandatory = $true)]
    [string]$fileLocation
)


# debug: print env varibles
# Get-ChildItem Env:

# wait for resources post initialization, otherwise API calls can will fail
Start-Sleep -Seconds 30

# restore language understanding model
Invoke-Expression "./RestoreLanguageUnderstanding.ps1 -fileLocation $fileLocation"

# restore bot
Invoke-Expression  "./RestoreBot.ps1 -fileLocation $fileLocation"
