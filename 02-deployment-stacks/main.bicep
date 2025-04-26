targetScope = 'subscription'

param location string = 'westeurope'

@secure()
param administratorLoginPassword string

var abbrs = loadJsonContent('../abbreviations.json')

var names = {
  rgDatabases: '${abbrs.resourcesResourceGroups}databases'
  rgApps: '${abbrs.resourcesResourceGroups}apps'
  sqlServer: '${abbrs.sqlServers}s001'
  sqlElasticPool: '${abbrs.sqlServersElasticPool}ep001'
  sqlDatabasePrefix: '${abbrs.sqlServersDatabases}db'
}

module dbRg 'br/public:avm/res/resources/resource-group:0.4.1' = {
  name: 'rgDbDeployment'
  params: {
    name: names.rgDatabases
    location: location
    tags: {
      Environment: 'Non-Prod'
      'hidden-title': 'This is visible in the resource name'
      Role: 'DeploymentValidation'
    }
  }
}

module appsRg 'br/public:avm/res/resources/resource-group:0.4.1' = {
  name: 'rgAppsDeployment'
  params: {
    name: names.rgApps
    location: location
    tags: {
      Environment: 'Non-Prod'
      'hidden-title': 'This is visible in the resource name'
      Role: 'DeploymentValidation'
    }
  }
}

// Note: Get list of SKUs with `az sql elastic-pool list-editions -l westeurope`

module server 'br/public:avm/res/sql/server:0.15.1' = {
  name: 'serverDeployment'
  scope: resourceGroup(names.rgDatabases)
  params: {
    name: names.sqlServer
    administratorLogin: 'rainer'
    administratorLoginPassword: administratorLoginPassword
    elasticPools: [
      {
        name: names.sqlElasticPool
        maxSizeBytes: 5 * 1024 * 1024 * 1000
        perDatabaseSettings: {
          maxCapacity: '5'
          minCapacity: '0.5'
        }
        sku: {
          name: 'BasicPool'
          capacity: 50
        }
        zoneRedundant: false
      }
    ]
    location: location
  }
  dependsOn: [
    dbRg
  ]
}

module sqlDb './sql-db.bicep' = {
  scope: resourceGroup(names.rgDatabases)
  params: {
    sqlServerName: names.sqlServer
    elasticPoolName: names.sqlElasticPool
    dbCount: 2
    sqlDatabasePrefix: names.sqlDatabasePrefix
  }
  dependsOn: [
    server
  ]
}

module containerGroup 'br/public:avm/res/container-instance/container-group:0.5.0' = {
  name: 'containerGroupDeployment'
  scope: resourceGroup(names.rgApps)
  params: {
    location: location
    availabilityZone: -1
    containers: [
      {
        name: 'webfe'
        properties: {
          image: 'mcr.microsoft.com/azuredocs/aci-helloworld'
          ports: [
            {
              port: 80
              protocol: 'Tcp'
            }
          ]
          resources: {
            requests: {
              cpu: 1
              memoryInGB: '1'
            }
          }
        }
      }
    ]
    name: '${abbrs.containerInstanceContainerGroups}webfe'
    ipAddress: {
      ports: [
        {
          port: 80
          protocol: 'Tcp'
        }
      ]
    }
  }
  dependsOn: [
    appsRg
  ]
}
