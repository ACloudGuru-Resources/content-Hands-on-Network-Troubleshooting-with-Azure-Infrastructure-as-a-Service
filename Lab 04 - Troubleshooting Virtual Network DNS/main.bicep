param location string = resourceGroup().location

var broken = false

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

resource workloadvnet 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'workloadvnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'web-subnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
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
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'jump-subnet'
        properties: {
          addressPrefix: '10.1.0.0/24'
          networkSecurityGroup: {
            id: nsgjumpboxvnet.id
          }
        }
      }
    ]
  }
}

resource vnetpeer1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  name: '${workloadvnet.name}/peer1'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: jumpboxvnet.id
    }
  }
}

resource vnetpeer2 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  name: '${jumpboxvnet.name}/peer1'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: workloadvnet.id
    }
  }
}

resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location: 'global'
  name: 'lab.vnet'
}

resource ARecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: 'lab.vnet/escape'
  dependsOn: [
    dnsZone
  ]
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: broken ? '10.0.0.81' : '10.0.0.80'
      }
    ]
  }
}

resource dnsZoneLinkToWorkloadvnet'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'workloadvnet'
  parent: dnsZone
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
        id: workloadvnet.id
    }
  }
}

resource dnsZoneLinkToJumpboxvnet'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if(broken==false) {
  name: 'jumpboxvnet'
  parent: dnsZone
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
        id: jumpboxvnet.id
    }
  }
}

resource nsgjumpboxvnet 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: 'nsg-jumpboxvnet'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow inbound RDP jumpboxes'
        properties: {
          description: 'Allow RDP jumpboxes'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          destinationAddressPrefix: '10.1.0.0/24'
          sourceAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow outbound HTTP from jumpbox subnet to web subnet'
        properties: {
          description: 'Allow outbound HTTP from jumpbox subnet to web subnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '10.1.0.0/24'
          destinationAddressPrefix: '10.0.0.0/24'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'Deny outbound from jumpboxvnet to workloadvnet'
        properties: {
          description: 'Deny outbound from jumpboxvnet to workloadvnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '10.1.0.0/16'
          destinationAddressPrefix: '10.0.0.0/16'
          access: 'Deny'
          priority: 200
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource jumpbox1pip 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: 'jumpbox1pip1'
  sku: {
    name: 'Standard'
  }
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
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
          privateIPAddress: '10.1.0.5'
          publicIPAddress: {
            id: jumpbox1pip.id
          }
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
        'https://raw.githubusercontent.com/ACloudGuru-Resources/content-Hands-on-Network-Troubleshooting-with-Azure-Infrastructure-as-a-Service/master/Lab%2004%20-%20Troubleshooting%20Virtual%20Network%20DNS/Initialize-JumpBox1.ps1'
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
          privateIPAddress: '10.0.0.80'
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
        'https://raw.githubusercontent.com/ACloudGuru-Resources/content-Hands-on-Network-Troubleshooting-with-Azure-Infrastructure-as-a-Service/master/Lab%2004%20-%20Troubleshooting%20Virtual%20Network%20DNS/Initialize-WebServer.ps1'
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Bypass -File Initialize-WebServer.ps1'
    }
  }
}

output vmsWithLogin array  = [
  {
    name: 'jumpbox1'
    showPrivateIp: false
    showPublicIp: true
    showFqdn: false
  }
]
