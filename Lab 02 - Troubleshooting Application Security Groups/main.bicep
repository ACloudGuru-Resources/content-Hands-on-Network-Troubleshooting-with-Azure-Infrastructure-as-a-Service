param location string = resourceGroup().location

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
      {
        name: 'asg-subnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
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
        name: 'AllowRDP'
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
          applicationGatewayBackendAddressPools: [
            appgw1.properties.backendAddressPools[0]
          ]
        }
      }
    ]
  }
}

resource webserver 'Microsoft.Compute/virtualMachines@2020-12-01' = [for i in range(1, 2): {
  name: 'webserver${i}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: 'webserver${i}'
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
}]
resource webserverCSE 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = [for i in range(1, 2): {
  parent: resourceId('Microsoft.Compute/virtualMachines@2020-12-01', 'webserver${i}')
  name: 'webserver${i}-cse'
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
      commandToExecute: 'powershell.exe -ExecutionPolicy Bypass -File Initialize-WebServer.ps1'
    }
  }
}]

resource appgw1pip 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'appgw1pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource appgw1 'Microsoft.Network/applicationGateways@2021-05-01' = {
  name: 'appgw1'
  location: location
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: vnet1.properties.subnets[2].id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          publicIPAddress: {
            id: appgw1pip.id
          }
        }
      }
      {
        name: 'appGwPrivateFrontendIp'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.2.80'
          subnet: vnet1.properties.subnets[2].id
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'webServerBackendPool'
        properties: {
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'HTTP'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
        }
      }
    ]
    httpListeners: [
      {
        name: 'privateListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', 'appgw1', 'appGwPrivateFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', 'appgw1', 'port_80')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'RoutePrivateHTTPToBackend'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', 'appgw1', 'privateListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', 'appgw1', 'webServerBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', 'appgw1', 'HTTP')
          }
        }
      }
    ]
    enableHttp2: false
    autoscaleConfiguration: {
      minCapacity: 0
      maxCapacity: 10
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
