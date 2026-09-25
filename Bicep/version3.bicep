targetScope = 'resourceGroup'

param environment string
param location string = 'uksouth'
param vmCount int = 2
param adminUsername string

@secure()
param adminSshKey string

param clientHosts array

// Module 1: Deploy Backend Application Virtual Machines
module vmCluster './modules/vm-cluster.bicep' = {
  name: 'vmClusterDeployment'
  params: {
    location: location
    environment: environment
    vmCount: vmCount
    adminUsername: adminUsername
    adminSshKey: adminSshKey
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet-spoke-prod', 'snet-vms')
  }
}

// Module 2: Shared Application Gateway routing traffic to the VM Cluster IPs
module appGateway './modules/appgateway.bicep' = {
  name: 'appGatewayDeployment'
  params: {
    location: location
    appGatewayName: 'agw-shared-${environment}-001'
    clientHosts: clientHosts
    backendTargetIps: vmCluster.outputs.vmPrivateIps // Dynamically pass array of VM IPs
  }
}

output backendVmIps array = vmCluster.outputs.vmPrivateIps
