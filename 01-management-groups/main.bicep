targetScope = 'managementGroup'

@description('The ID of the root management group')
param rootGroupId string

@description('The location to deploy the resources to')
param location string

var abbrs = loadJsonContent('../abbreviations.json')

module topGroup 'br/public:avm/res/management/management-group:0.1.2' = {
  name: 'topGroup'
  params: {
    name: '${abbrs.managementManagementGroups}acme'
    displayName: 'Acme Corp'
    location: location
    parentId: rootGroupId
  }
}

module sandboxGroup 'br/public:avm/res/management/management-group:0.1.2' = {
  name: 'sandboxGroup'
  params: {
    name: '${abbrs.managementManagementGroups}sandbox'
    displayName: 'Sandbox'
    location: location
    parentId: topGroup.outputs.name
  }
}

output topGroupId string = topGroup.outputs.name
output sandboxGroupId string = sandboxGroup.outputs.name
