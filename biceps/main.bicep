@description('Specifies the location for resources.')
param location string = 'southeastasia'


// AZURE DIGITAL TWINS
param digitalTwinsName string = 'adt-store'

resource digitalTwins 'Microsoft.DigitalTwins/digitalTwinsInstances@2022-10-31' = {
  name: digitalTwinsName
  location: location
}

// STORAGE ACCOUNT FOR AZURE DIGITAL TWINS 3D SCENES
param storageAccountName string = 'ADTStoreStorageAccount'

@allowed([
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GRS'
  'Standard_GZRS'
  'Standard_LRS'
  'Standard_RAGRS'
  'Standard_RAGZRS'
  'Standard_ZRS'
])
param sku string = 'Standard_RAGRS'

@allowed([
  'BlobStorage'
  'BlockBlobStorage'
  'FileStorage'
  'Storage'
  'StorageV2'
])
param kind string = 'StorageV2'

param containerName string = 'storedigitaltwinscontainer'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: toLower(storageAccountName)
  location: location
  kind: kind
  sku: {
    name: sku
  }
}

resource storageAccountBlobService 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  name: 'default'
  parent: storageAccount
  properties: {
    cors: {
      corsRules: [
        {
          allowedHeaders: [
            'Authorization,x-ms-version,x-ms-blob-type'
          ]
          allowedMethods: [
            'GET', 'POST', 'OPTIONS', 'PUT'
          ]
          allowedOrigins: [
            'https://explorer.digitaltwins.azure.net'
          ]
          exposedHeaders: []
          maxAgeInSeconds: 0
        }
      ]
    }
  }
}

resource storageAccountContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  name: containerName
  parent: storageAccountBlobService
}

// ROLE ASSIGNMENTS FOR ADT AND SA
param principalId string

@allowed([
  'Device'
  'ForeignGroup'
  'Group'
  'ServicePrincipal'
  'User'
])
param principalType string = 'Group'

var azureDigitalTwinsDataOwnerRoleDefinitionId = 'bcd981a7-7f74-457b-83e1-cceb9e632ffe'

resource roleAssignmentDigitalTwins 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, azureDigitalTwinsDataOwnerRoleDefinitionId)
  scope: digitalTwins
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureDigitalTwinsDataOwnerRoleDefinitionId)
    principalId: principalId
    principalType: principalType
  }
}

var storageBlobDataOwnerRoleDefinitionId = 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'

resource roleAssignmentStorageAccount 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, storageBlobDataOwnerRoleDefinitionId)
  scope: storageAccount
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataOwnerRoleDefinitionId)
    principalId: principalId
    principalType: principalType
  }
}
