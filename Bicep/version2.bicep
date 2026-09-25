// network-vm-tier.bicep
param location string = 'uksouth'
param firewallPrivateIp string = '10.0.0.4'
param adminUsername string = 'azureuser'

@secure()
param adminSshKey string

// 1. User-Defined Route (Force all VM egress through central Firewall)
resource routeTable 'Microsoft.Network/routeTables@2023-09-01' = {
  name: 'rt-vm-spoke-to-firewall'
  location: location
  properties: {
    routes: [
      {
        name: 'default-egress'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}

// 2. Strict NSG (Allow HTTPS from Hub VNet only, deny direct internet)
resource vmNsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-vm-app-subnet'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-Hub-Traffic'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '10.0.0.0/16' // Hub VNet CIDR
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// 3. VNet and VM Subnet
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-spoke-vms-001'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.1.0.0/16']
    }
    subnets: [
      {
        name: 'snet-app-vms'
        properties: {
          addressPrefix: '10.1.1.0/24'
          networkSecurityGroup: { id: vmNsg.id }
          routeTable: { id: routeTable.id }
        }
      }
    ]
  }
}

// 4. NIC for VM
resource vmNic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: 'nic-vm-app-001'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.1.1.10'
          subnet: { id: vnet.properties.subnets[0].id }
        }
      }
    ]
  }
}

// 5. Virtual Machine
resource appVm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: 'vm-app-prod-001'
  location: location
  properties: {
    hardwareProfile: { vmSize: 'Standard_D4s_v5' }
    osProfile: {
      computerName: 'vmappprod001'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [{ path: '/home/${adminUsername}/.ssh/authorized_keys', keyData: adminSshKey }]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: { createOption: 'FromImage', managedDisk: { storageAccountType: 'Premium_ZRS' } }
    }
    networkProfile: {
      networkInterfaces: [{ id: vmNic.id }]
    }
  }
}

output vmPrivateIp string = vmNic.properties.ipConfigurations[0].properties.privateIPAddress
