@minLength(3)
@maxLength(25)
param matchingBotName string = 'ctm-healthbot-demo'

@minLength(3)
@maxLength(25)
param healthInsightName string = 'healthinsights-ctm-cog'

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
    environmentVariables: []
    primaryScriptUri: 'https://raw.githubusercontent.com/microsoft/ClinicalTrialsBlueprint/task/tolehman/migrate_to_health_insights_api/arm-templates/restoreBot.ps1'
    supportingScriptUris: []
    timeout: 'PT30M'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
}

output healthInsightEndpoint string = healthInsight.properties.endpoint
output healthBotEndpoint string = healthbot.properties.botManagementPortalLink
