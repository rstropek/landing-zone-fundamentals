var abbrs = loadJsonContent('../abbreviations.json')

module storageAccount 'br/public:avm/res/storage/storage-account:0.19.0' = {
  name: '${abbrs.storageStorageAccounts}${uniqueString('cd001')}'
  params: {
    name: '${abbrs.storageStorageAccounts}${uniqueString('cd001')}'
    kind: 'BlobStorage'
    location: resourceGroup().location
    skuName: 'Standard_LRS'
    allowBlobPublicAccess: true
  }
}
