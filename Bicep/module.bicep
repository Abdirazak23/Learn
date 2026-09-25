param location string
param environment string
param vmCount int
param adminUsername string

@secure()
param adminSshKey string
param subnetId string

// Loop to create multiple NICs and VMs based on vmCount parameter
resource vmNics 'Microsoft.Network/networkInterfaces@2023-09-01' = [for i in range(0, vmCount): {
  name: 'nic-vm-\({environment}-\){i + 1}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: { id: subnetId }
        }
      }
    ]
  }
}]

resource vms 'Microsoft.Compute/virtualMachines@2023-09-01' = [for i in range(0, vmCount): {
  name: 'vm-\({environment}-\){i + 1}'
  location: location
  properties: {
    hardwareProfile: { vmSize: 'Standard_D4s_v5' }
    osProfile: {
      computerName: 'vm\({environment}\){i + 1}'
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
      networkInterfaces: [{ id: vmNics[i].id }]
    }
  }
}]

// Output array of private IPs to feed directly into Application Gateway backend pool
output vmPrivateIps array = [for i in range(0, vmCount): vmNics[i].properties.ipConfigurations[0].properties.privateIPAddress]
