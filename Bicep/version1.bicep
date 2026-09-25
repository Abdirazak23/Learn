// main.bicep
@description('Username for the Virtual Machine')
param adminUsername string = 'azureuser'

@description('SSH Public Key for authentication')
@secure()
param adminSshKey string

@description('Azure region for deployment')
param location string = 'uksouth'

// 1. Network Interface
resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: 'nic-vm-simple-001'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet-existing', 'snet-app')
          }
        }
      }
    ]
  }
}

// 2. Linux Virtual Machine
resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: 'vm-simple-001'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v5'
    }
    osProfile: {
      computerName: 'vmsimple001'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: adminSshKey
            }
          ]
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
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

output vmId string = vm.id
