var abbrs = loadJsonContent('../abbreviations.json')

// Note: You can find the id of policy definitions with e.g. 
// `az policy definition list --query "[?displayName!=null && contains(displayName,'tag')].{displayName: displayName, id: id, version: metadata.version}" --output json`
var policyDefinitions = {
  storageDisablePublicAccess: '/providers/Microsoft.Authorization/policyDefinitions/b2982f36-99f2-4db5-8eff-283140c09693'
}

module storageAccount 'br/public:avm/res/storage/storage-account:0.19.0' = {
  name: '${abbrs.storageStorageAccounts}${uniqueString('sa001')}'
  params: {
    name: '${abbrs.storageStorageAccounts}${uniqueString('sa001')}'
    kind: 'BlobStorage'
    location: resourceGroup().location
    skuName: 'Standard_LRS'
    allowBlobPublicAccess: true
  }
}

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: 'Storage accounts should disable public network access'
  properties: {
    #disable-next-line use-resource-id-functions
    policyDefinitionId: policyDefinitions.storageDisablePublicAccess
    parameters: {
      effect: { value: 'Audit' }
    }
  }
}
