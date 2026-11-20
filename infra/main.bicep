// BrezyWeather forecast API resources: a storage account and the API's managed identity.

@description('Azure region for every resource.')
param location string = resourceGroup().location

@description('Environment tag.')
param environment string = 'staging'

@description('Who gets paged for the forecast API.')
param onCallContact string = 'platform-oncall@brezyweather.example'

var tags = {
  app: 'brezyweather-forecast-api'
  environment: environment
  team: 'platform'
  onCall: onCallContact
}

resource forecastStorage 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: 'stbwfcmcp${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    supportsHttpsTrafficOnly: true
  }
}

resource forecastIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-brezyweather-forecast-api'
  location: location
  tags: tags
}

output storageAccountName string = forecastStorage.name
