targetScope = 'tenant'

@description('Provide the name of the subscription.')
param subscriptionName string

@description('Provide the full resource ID of the management group to create the subscription in.')
param managementGroupId string

resource managementGroup 'Microsoft.Management/managementGroups@2023-04-01' existing = {
  name: managementGroupId
}

resource subscriptionResources 'Microsoft.Management/managementGroups/subscriptions@2023-04-01' = {
  parent: managementGroup
  name: subscriptionName
}


