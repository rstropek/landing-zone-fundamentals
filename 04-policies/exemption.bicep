param policyAssignmentId string

var abbrs = loadJsonContent('../abbreviations.json')

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' existing = {
  name: '${abbrs.storageStorageAccounts}${uniqueString('sa001')}'
}

resource exception 'Microsoft.Authorization/policyExemptions@2022-07-01-preview' = {
  scope: storageAccount
  name: 'Public access allowed'
  properties: {
    description: 'Here we describe the exemption'
    displayName: 'Name of exemption'
    policyAssignmentId: policyAssignmentId
    exemptionCategory: 'Mitigated'
  }
}
