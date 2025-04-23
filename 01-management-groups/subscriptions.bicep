targetScope = 'tenant'

param managementGroupId string
param subscriptionId string

resource managementGroup 'Microsoft.Management/managementGroups@2023-04-01' existing = {
  name: managementGroupId
}

resource subscriptionResources 'Microsoft.Management/managementGroups/subscriptions@2023-04-01' = {
  parent: managementGroup
  name: subscriptionId
}
