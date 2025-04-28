targetScope = 'tenant'

@description('Provide the full resource ID of billing scope to use for subscription creation.')
param billingScope string

@description('Provide the name of the subscription to create.')
param subscriptionName string

@description('Provide the display name of the subscription to create.')
param subscriptionDisplayName string

resource subscriptionAlias 'Microsoft.Subscription/aliases@2024-08-01-preview' = {
  scope: tenant()
  name: subscriptionName
  properties: {
    workload: 'Production'
    displayName: subscriptionDisplayName
    billingScope: billingScope
  }  
}

output subscriptionId string = subscriptionAlias.properties.subscriptionId
