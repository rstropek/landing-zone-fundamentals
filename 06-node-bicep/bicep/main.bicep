targetScope = 'tenant'

@description('Provide the full resource ID of billing scope to use for subscription creation.')
param billingScope string

@description('Provide the name of the subscription to create.')
param subscriptionName string

@description('Provide the display name of the subscription to create.')
param subscriptionDisplayName string

@description('Provide the full resource ID of the management group to create the subscription in.')
param managementGroupId string

module subscription 'subscription.bicep' = {
  name: 'subscriptionDeployment'
  params: {
    billingScope: billingScope
    subscriptionName: subscriptionName
    subscriptionDisplayName: subscriptionDisplayName
  }
}

module mgAssignment 'mg-assignment.bicep' = {
  name: 'mgAssignmentDeployment'
  params: {
    subscriptionName: subscription.outputs.subscriptionId
    managementGroupId: managementGroupId
  }
}
