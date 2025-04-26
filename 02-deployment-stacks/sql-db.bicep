param location string = resourceGroup().location
param elasticPoolName string
param sqlServerName string
param dbCount int = 2
param sqlDatabasePrefix string

resource sqlServer 'Microsoft.Sql/servers@2024-05-01-preview' existing = {
  name: sqlServerName
}

resource elasticPool 'Microsoft.Sql/servers/elasticPools@2024-05-01-preview' existing = {
  parent: sqlServer
  name: elasticPoolName
}

resource sqlDb 'Microsoft.Sql/servers/databases@2024-05-01-preview' = [for i in range(1, dbCount): {
  name: '${sqlDatabasePrefix}-${i}'
  parent: sqlServer
  location: location
  properties: {
    elasticPoolId: elasticPool.id
  }
}]
