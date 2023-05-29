param serviceName string
param linuxFxVersion string = 'node|14-lts'
param farmSKU string = 'F1'
param botSKU string = 'F0'
param location string = 'eastus'
param hbsRestoreFile string = 'https://xxxxxxxxx.blob.core.windows.net/templates/botTemplate.hbs'

resource healthbot 'Microsoft.HealthBot/healthBots@2022-08-08' = {
  name: '${serviceName}-bot'
  location: location
  properties: {
    keyVaultProperties: {
      keyName: 'string'
      keyVaultUri: 'string'
      keyVersion: 'string'
      userIdentity: 'string'
    }
  }
  sku: {
    name: botSKU
  }
}

resource farm 'Microsoft.Web/serverfarms@2022-03-01' = {
  location: location
  name: '${serviceName}-farm'
  kind: 'linux'
  sku: {
    name: farmSKU
  }
  properties: {
    reserved: true
  }
}

resource webapp 'Microsoft.Web/sites@2022-03-01' = {
  name: '${serviceName}-webapp'
  location: location
  properties: {
    serverFarmId: farm.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      appSettings: [
        {
          name: 'PORT'
          value: '80'
        }
        {
          name: 'APP_SECRET'
          value: healthbot.listSecrets().secrets[0].value
        }
        {
          name: 'WEBCHAT_SECRET'
          value: healthbot.listSecrets().secrets[1].value
        }
      ]
    }
  }
}

resource srcControls 'Microsoft.Web/sites/sourcecontrols@2021-01-01' = {
  name: '${webapp.name}/web'
  properties: {
    repoUrl: 'https://github.com/microsoft/HealthBotContainerSample'
    branch: 'master'
    isManualIntegration: true
  }
}

resource importBotScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: '${serviceName}-RestoreBotScript'
  location: location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '3.0'
    scriptContent: loadTextContent('restoreBot.ps1')
    retentionInterval: 'P1D'
    arguments: '-secret ${healthbot.listSecrets().secrets[2].value} -baseUrl ${healthbot.properties.botManagementPortalLink} -hbsRestoreFile ${hbsRestoreFile}'
  }
}
