param location string = resourceGroup().location

var broken = true

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

resource vnet1 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'vnet1'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'jump-subnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsgjumpsubnet.id
          }
        }
      }
      {
        name: 'web-subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: nsgwebsubnet.id
          }
        }
      }
    ]
  }
}

resource nsgwebsubnet 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: 'nsg-web-subnet'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow web traffic to web subnet'
        properties: {
          description: 'Allow web traffic to web subnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Deny all traffic to web subnet'
        properties: {
          description: 'Deny all traffic to web subnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '10.0.1.0/24'
          access: 'Deny'
          priority: 200
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource nsgjumpsubnet 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: 'nsg-jump-subnet'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow inbound RDP jumpbox subnet'
        properties: {
          description: 'Allow RDP jumpbox subnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '10.0.0.0/24'
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
          sourceAddressPrefix: '10.0.0.0/24'
          destinationAddressPrefix: '10.0.1.0/24'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'Deny outbound to vnet1 from jumpbox subnet'
        properties: {
          description: 'Deny outbound to vnet1 from jumpbox subnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '10.0.0.0/24'
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
          privateIPAddress: '10.0.0.5'
          publicIPAddress: {
            id: jumpbox1pip.id
          }
          subnet: {
            id: vnet1.properties.subnets[0].id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgjumpbox1nic1.id
    }
  }
}

resource nsgjumpbox1nic1 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: 'nsg-jumpbox1nic1'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow Remote Desktop to jumpbox1'
        properties: {
          description: 'Allow Remote Desktop to jumpbox1'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '10.0.0.5'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
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
        'https://raw.githubusercontent.com/ACloudGuru-Resources/content-Hands-on-Network-Troubleshooting-with-Azure-Infrastructure-as-a-Service/master/Lab%2001%20-%20Troubleshooting%20Network%20Security%20Groups/Initialize-JumpBox1.ps1'
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
          privateIPAddress: '10.0.1.80'
          subnet: {
            id: vnet1.properties.subnets[1].id
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
        'https://raw.githubusercontent.com/ACloudGuru-Resources/content-Hands-on-Network-Troubleshooting-with-Azure-Infrastructure-as-a-Service/master/Lab%2001%20-%20Troubleshooting%20Network%20Security%20Groups/Initialize-WebServer1.ps1'
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Bypass -File Initialize-WebServer1.ps1'
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
            id: vnet1.properties.subnets[1].id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgfileserver1nic1.id
    }
  }
}
resource nsgfileserver1nic1 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: 'nsg-fileserver1nic1'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowSMBtoFileServer1'
        properties: {
          description: 'Allow SMB traffic to web subnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '445'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '10.0.1.139'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
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
        'https://raw.githubusercontent.com/ACloudGuru-Resources/content-Hands-on-Network-Troubleshooting-with-Azure-Infrastructure-as-a-Service/master/Lab%2001%20-%20Troubleshooting%20Network%20Security%20Groups/Initialize-FileServer1.ps1'
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
