@minLength(3)
@maxLength(30)
param matchingBotName string = 'ctm-healthbot-template'

@minLength(2)
@maxLength(64)
param healthInsightsName string = 'ctm-healthinsights-cogs'

@minLength(2)
@maxLength(64)
param languageUnderstandingName string = 'ctm-CLU-cogs'

param resourceTags object = {
  Environment: 'Prod'
  Project: 'Health Insights Trial Matching bot'
}

param location string = resourceGroup().location

var fileLocation = 'https://raw.githubusercontent.com/microsoft/ClinicalTrialsBlueprint/master'

resource healthbot 'Microsoft.HealthBot/healthBots@2022-08-08' = {
  name: matchingBotName
  location: location
  sku: { name: 'S1' }
  properties: {}
  tags: resourceTags
}

resource healthInsights 'Microsoft.CognitiveServices/accounts@2022-12-01' = {
  name: healthInsightsName
  location: location
  sku: {
    name: 'S0'
  }
  kind: 'HealthInsights'
  properties: {
    customSubDomainName: healthInsightsName
    publicNetworkAccess: 'Enabled'
  }
  tags: resourceTags
}

resource runPowerShellInline 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'runPowerShellInline'
  tags: resourceTags
  kind: 'AzurePowerShell'
  location: location
  properties: {
    forceUpdateTag: '1'
    azPowerShellVersion: '9.7'
    arguments: '-fileLocation ${fileLocation}'
    environmentVariables: [
      {
        name: 'HEALTH_INSIGHTS_ENDPOINT'
        value: healthInsights.properties.endpoint
      }
      {
        name: 'HEALTH_INSIGHTS_KEY'
        secureValue: healthInsights.listKeys().key1
      }
      {
        name: 'CLU_ENDPOINT'
        value: langUnderstanding.properties.endpoint
      }
      {
        name: 'CLU_KEY'
        secureValue: langUnderstanding.listKeys().key1
      }
      {
        name: 'HEALTH_BOT_ENDPOINT'
        value: healthbot.properties.botManagementPortalLink
      }
      {
        name: 'HEALTH_BOT_SECRET'
        secureValue: healthbot.listSecrets().secrets[2].value
      }
    ]
    primaryScriptUri: '${fileLocation}/scripts/MainRestore.ps1'
    supportingScriptUris: [
      '${fileLocation}/scripts/RestoreBot.ps1'
      '${fileLocation}/scripts/RestoreLanguageUnderstanding.ps1'
    ]
    timeout: 'PT30M'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
}

resource langUnderstanding 'Microsoft.CognitiveServices/accounts@2022-12-01' = {
  name: languageUnderstandingName
  location: location
  sku: {
    name: 'S'
  }
  kind: 'TextAnalytics'
  identity: {
    type: 'None'
  }
  properties: {
    customSubDomainName: languageUnderstandingName
    publicNetworkAccess: 'Enabled'
  }
}

output healthInsightsEndpoint string = healthInsights.properties.endpoint
output healthBotEndpoint string = healthbot.properties.botManagementPortalLink
