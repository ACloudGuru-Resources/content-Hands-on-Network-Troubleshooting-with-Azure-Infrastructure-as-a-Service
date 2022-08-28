param location string = resourceGroup().location

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'ManagedIdentity'
  location: location
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(managedIdentity.id, resourceGroup().id)
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
          networkSecurityGroup: {
            id: nsgdefault.id
          }
        }
      }
      {
        name: 'data-subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: nsgdefault.id
          }
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
            id: nsgdefault.id
          }
        }
      }
    ]
  }
}

resource vnetpeer1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  name: '${workloadvnet.name}/peertojumpboxvnet'
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
  name: '${jumpboxvnet.name}/peertoworkloadvnet'
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
        ipv4Address: '10.0.0.80'
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

resource dnsZoneLinkToJumpboxvnet'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
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

resource nsgdefault 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: 'nsg-default'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow inbound RDP from anywhere to jumpbox virtual network'
        properties: {
          description: 'Allow inbound RDP from anywhere to jumpbox virtual network'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          destinationAddressPrefix: '10.1.0.0/16'
          sourceAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow HTTP traffic from virtual network to web subnet'
        properties: {
          description: 'Allow HTTP traffic from virtual network to web subnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '10.0.0.0/24'
          access: 'Allow'
          priority: 150
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow SMB traffic from web subnet to data subnet'
        properties: {
          description: 'Allow SMB traffic from web subnet to data subnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '445'
          sourceAddressPrefix: '10.0.0.0/24'
          destinationAddressPrefix: '10.0.1.0/24'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
      {
        name: 'Deny all inbound to virtual networks'
        properties: {
          description: 'Deny all inbound to virtual networks'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Deny'
          priority: 4096
          direction: 'Inbound'
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
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      fileUris: [
        'https://raw.githubusercontent.com/ACloudGuru-Resources/content-Hands-on-Network-Troubleshooting-with-Azure-Infrastructure-as-a-Service/master/Lab%2006%20-%20Troubleshooting%20Azure%20Infrastructure%20as%20a%20Service%20(IaaS)%20Networking/Initialize-JumpBox1.ps1'
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Bypass -File Initialize-JumpBox1.ps1'
    }
  }
}

resource jumpbox2pip 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: 'jumpbox2pip1'
  sku: {
    name: 'Standard'
  }
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource jumpbox2nic1 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'jumpbox2nic1'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'jumpbox1nic1ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.1.0.6'
          publicIPAddress: {
            id: jumpbox2pip.id
          }
          subnet: {
            id: jumpboxvnet.properties.subnets[0].id
          }
        }
      }
    ]
  }
}

resource jumpbox2 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'jumpbox2'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: 'jumpbox2'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        name: 'jumpbox2osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: jumpbox2nic1.id
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

resource jumpbox2CSE 'Microsoft.Compute/virtualMachines/extensions@2019-03-01' = {
  parent: jumpbox2
  name: 'jumpbox2-cse'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      fileUris: [
        'https://raw.githubusercontent.com/ACloudGuru-Resources/content-Hands-on-Network-Troubleshooting-with-Azure-Infrastructure-as-a-Service/master/Lab%2006%20-%20Troubleshooting%20Azure%20Infrastructure%20as%20a%20Service%20(IaaS)%20Networking/Jumpbox2.sh'
      ]
      commandToExecute: 'sh Jumpbox2.sh'
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
        'https://raw.githubusercontent.com/ACloudGuru-Resources/content-Hands-on-Network-Troubleshooting-with-Azure-Infrastructure-as-a-Service/master/Lab%2006%20-%20Troubleshooting%20Azure%20Infrastructure%20as%20a%20Service%20(IaaS)%20Networking/Initialize-WebServer.ps1'
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Bypass -File Initialize-WebServer.ps1'
    }
  }
}

resource fileserver1nic1 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'fileserver1nic1'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'fileserver1nic1ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.1.139'
          subnet: {
            id: workloadvnet.properties.subnets[1].id
          }
        }
      }
    ]
  }
}

resource fileserver1 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'fileserver1'
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
      computerName: 'fileserver1'
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
        name: 'fileserver1osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: fileserver1nic1.id
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
resource fileserver1CSE 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: fileserver1
  name: 'fileserver1-cse'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      fileUris: [
        'https://raw.githubusercontent.com/ACloudGuru-Resources/content-Hands-on-Network-Troubleshooting-with-Azure-Infrastructure-as-a-Service/master/Lab%2006%20-%20Troubleshooting%20Azure%20Infrastructure%20as%20a%20Service%20(IaaS)%20Networking/Initialize-FileServer1.ps1'
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Bypass -File Initialize-FileServer1.ps1'
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
