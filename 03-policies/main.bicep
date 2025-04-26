targetScope = 'managementGroup'

var version = '1.0.0-preview'

var abbrs = loadJsonContent('../abbreviations.json')

// Note: You can find the id of policy definitions with e.g. 
// `az policy definition list --query "[?displayName!=null && contains(displayName,'tag')].{displayName: displayName, id: id, version: metadata.version}" --output json`
var policyDefinitions = {
  allowedLocations: '/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c'
  requiredTag: '/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99'
}

resource policySet 'Microsoft.Authorization/policySetDefinitions@2025-01-01' = {
  name: 'general-housekeeping'
  properties: {
    description: 'General housekeeping policies'
    displayName: 'General Housekeeping'
    metadata: {
      version: version
      category: 'General'
      preview: true
    }
    parameters: {
    }

    policyDefinitions: [
      {
        // Allowed locations
        #disable-next-line use-resource-id-functions
        policyDefinitionId: policyDefinitions.allowedLocations
        parameters: {
          listOfAllowedLocations: { value: ['westeurope', 'swedencentral'] }
        }
      }
      {
        // Require a tag on resources
        #disable-next-line use-resource-id-functions
        policyDefinitionId: policyDefinitions.requiredTag
        parameters: {
          tagName: { value: 'environment' }
        }
      }
    ]
  }
}

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: 'general-housekeeping'
  properties: {
    policyDefinitionId: policySet.id
  }
}
