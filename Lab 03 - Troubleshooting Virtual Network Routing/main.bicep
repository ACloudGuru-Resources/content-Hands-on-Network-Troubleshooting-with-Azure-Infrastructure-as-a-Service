param location string = resourceGroup().location

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'ManagedIdentity'
  location: location
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(managedIdentity.id, resourceGroup().id, 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  scope: resourceGroup()
  properties: {
    description: 'Managed identity description'
    principalId: managedIdentity.properties.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalType: 'ServicePrincipal'
  }
}

resource hubvnet 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'hubvnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
          routeTable: {
            id: azureFirewallRoute.id
          }
        }
      }
    ]
  }
}

resource workloadvnet 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'workloadvnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'web-subnet'
        properties: {
          addressPrefix: '10.1.0.0/24'
        }
      }
    ]
  }
}

resource jumpboxvnet 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'jumpboxvnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.2.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'jump-subnet'
        properties: {
          addressPrefix: '10.2.0.0/24'
        }
      }
    ]
  }
}

resource vnetpeerjumpboxtohub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  name: '${jumpboxvnet.name}/peertohub'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubvnet.id
    }
  }
}

resource vnetpeerhubtojumpbox 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  name: '${hubvnet.name}/peertojumpbox'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: jumpboxvnet.id
    }
  }
}

resource vnetpeerworkloadtohub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  name: '${workloadvnet.name}/peertohub'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubvnet.id
    }
  }
}

resource vnetpeerhubtoworkload 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  name: '${hubvnet.name}/peertoworkload'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: workloadvnet.id
    }
  }
}

resource pipFirewall 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: 'pipAzureFirewall'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2020-05-01' = {
  name: 'AzureFirewall'
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
    ipConfigurations: [
      {
        name: 'AzureFirewallipconfig1'
        properties: {
          publicIPAddress: {
            id: pipFirewall.id
          }
          subnet: {
            id: hubvnet.properties.subnets[0].id
          }
        }
      }
    ]
    networkRuleCollections: [
      {
        name: 'AllowedNetworkRulesCollection'
        properties: {
            priority: 100
            action: {
                type: 'Allow'
            }
            rules: [
                {
                name: 'Allow HTTP to web subnet'  
                protocols: [
                    'TCP'
                ]
                sourceAddresses: [
                    '*'
                ]
                destinationAddresses: [
                    '10.1.0.0/24'
                ]
                sourceIpGroups: []
                destinationIpGroups: []
                destinationFqdns: []
                destinationPorts: [
                    '80'
                ]
            }
          ]
        }
      }
    ]
    natRuleCollections: [
      {
        name: 'AllowedDNatRuleCollection'
        properties: {
            priority: 100
            action: {
                type: 'Dnat'
            }
            rules: [
                {
                    name: 'Forward RDP traffic to jumpbox'
                    protocols: [
                        'TCP'
                    ]
                    translatedAddress: '10.2.0.5'
                    translatedPort: '3389'
                    sourceAddresses: [
                        '*'
                    ]
                    sourceIpGroups: []
                    destinationAddresses: [
                        pipFirewall.properties.ipAddress
                    ]
                    destinationPorts: [
                        '3389'
                    ]
                }
            ]
        }
      }
    ]
  }
}

resource azureFirewallRoute 'Microsoft.Network/routeTables@2020-05-01' = {
  name: 'udrAzureFirewallRoute'
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'DefaultRoute'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'Internet'
        }
      }
    ]
  }
}

resource jumpbox1nic1 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'jumpbox1nic1'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'jumpbox1nic1ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.2.0.5'
          subnet: {
            id: jumpboxvnet.properties.subnets[0].id
          }
        }
      }
    ]
  }
}

resource jumpbox1 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'jumpbox1'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: 'jumpbox1'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter'
        version: 'latest'
      }
      osDisk: {
        name: 'jumpbox1osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: jumpbox1nic1.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
}

resource jumpbox1CSE 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: jumpbox1
  name: 'jumpbox1-cse'
  dependsOn: [
    webserver1CSE
  ]
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      fileUris: [
        'https://raw.githubusercontent.com/ACloudGuru-Resources/content-Hands-on-Network-Troubleshooting-with-Azure-Infrastructure-as-a-Service/master/Lab%2003%20-%20Troubleshooting%20Virtual%20Network%20Routing/Initialize-JumpBox1.ps1'
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Bypass -File Initialize-JumpBox1.ps1'
    }
  }
}

resource webserver1nic1 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'webserver1nic1'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'webserver1nic1ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.1.0.80'
          subnet: {
            id: workloadvnet.properties.subnets[0].id
          }
        }
      }
    ]
  }
}

resource webserver1 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'webserver1'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: 'webserver1'
      adminUsername: 'DoNotUse'
      adminPassword: 'SuperSecureP@55w0rd'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter'
        version: 'latest'
      }
      osDisk: {
        name: 'webserver1osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: webserver1nic1.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
}

resource webserver1CSE 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: webserver1
  name: 'webserver1-cse'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      fileUris: [
        'https://raw.githubusercontent.com/ACloudGuru-Resources/content-Hands-on-Network-Troubleshooting-with-Azure-Infrastructure-as-a-Service/master/Lab%2003%20-%20Troubleshooting%20Virtual%20Network%20Routing/Initialize-WebServer.ps1'
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Bypass -File Initialize-WebServer.ps1'
    }
  }
}

output vmsWithLogin array = [
  {
    name: 'jumpbox1'
    showPrivateIp: false
    showPublicIp: true
    showFqdn: false
  }
]
