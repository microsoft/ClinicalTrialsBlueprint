@minLength(3)
@maxLength(25)
param matchingBotName string = 'ctm-healthbot-demo'

@minLength(3)
@maxLength(25)
param healthInsightName string = 'healthinsights-ctm-cog'

@minLength(3)
@maxLength(25)
param languageUnderstandingName string = 'CLU-ctm-cog'

param resourceTags object = {
  Environment: 'Prod'
  Project: 'Health Insight Trial Matching bot'
}

param location string = resourceGroup().location

resource healthbot 'Microsoft.HealthBot/healthBots@2022-08-08' = {
  name: matchingBotName
  location: location
  sku: { name: 'F0' }
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
    // containerSettings: {
    //   containerGroupName: 'healthbot-deploy-script'
    // }
    azPowerShellVersion: '9.7'
    arguments: '-secret ${healthbot.listSecrets().secrets[2].value} -baseUrl ${healthbot.properties.botManagementPortalLink}  -hbsRestoreFile https://raw.githubusercontent.com/microsoft/ClinicalTrialsBlueprint/task/tolehman/migrate_to_health_insights_api/bot-templates/ctm-bot.json'
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
    scriptContent: '''
      ./restoreBot.ps1
      ./restoreLanguageUnderstanding.ps1
    '''
    supportingScriptUris: [
      'https://raw.githubusercontent.com/microsoft/ClinicalTrialsBlueprint/task/tolehman/migrate_to_health_insights_api/arm-templates/restoreBot.ps1'
      'https://raw.githubusercontent.com/microsoft/ClinicalTrialsBlueprint/task/tolehman/migrate_to_health_insights_api/arm-templates/restoreLanguageUnderstanding.ps1'
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
    name: 'F0'
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
