@minLength(3)
@maxLength(30)
param matchingBotName string = 'ctm-healthbot-template'

@minLength(2)
@maxLength(64)
param healthInsightName string = 'ctm-healthinsights-cogs'

@minLength(2)
@maxLength(64)
param languageUnderstandingName string = 'ctm-CLU-cogs'

param resourceTags object = {
  Environment: 'Prod'
  Project: 'Health Insight Trial Matching bot'
}

param location string = resourceGroup().location
param fileLocation string = 'https://raw.githubusercontent.com/microsoft/ClinicalTrialsBlueprint/task/tolehman/migrate_to_health_insights_api/'

resource healthbot 'Microsoft.HealthBot/healthBots@2022-08-08' = {
  name: matchingBotName
  location: location
  sku: { name: 'S1' }
  properties: {}
  tags: resourceTags
}

resource healthInsight 'Microsoft.CognitiveServices/accounts@2022-12-01' = {
  name: healthInsightName
  location: location
  sku: {
    name: 'F0'
  }
  kind: 'HealthInsights'
  properties: {
    customSubDomainName: healthInsightName
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
    arguments: '-botEndpoint ${healthbot.properties.botManagementPortalLink} -botSecret ${healthbot.listSecrets().secrets[2].value} -cuiEndpoint ${healthInsight.properties.endpoint} -cuiKey ${healthInsight.listKeys().key1} -fileLocation ${fileLocation}'
    environmentVariables: [
      {
        name: 'HEALTH_INSIGHT_ENDPOINT'
        value: healthInsight.properties.endpoint
      }
      {
        name: 'HEALTH_INSIGHT_KEY'
        value: healthInsight.listKeys().key1
      }
      {
        name: 'CLU_KEY'
        value: lungUnderstanding.properties.endpoint
      }
      {
        name: 'CLU_ENDPOINT'
        value: lungUnderstanding.listKeys().key1
      }
    ]
    primaryScriptUri: '${fileLocation}/scripts/main-restore.ps1'
    supportingScriptUris: [
      '${fileLocation}/scripts/RestoreBot.ps1'
      '${fileLocation}/scripts/RestoreLanguageUnderstanding.ps1'
    ]
    timeout: 'PT30M'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
}

resource lungUnderstanding 'Microsoft.CognitiveServices/accounts@2022-12-01' = {
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

output healthInsightEndpoint string = healthInsight.properties.endpoint
output healthBotEndpoint string = healthbot.properties.botManagementPortalLink
