using './main.bicep'

param environment = 'prod'
param location = 'uksouth'
param vmCount = 3
param adminUsername = 'opsadmin'
param adminSshKey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC...'

// Client-specific routing entries dynamically mapped to the backend VM cluster
param clientHosts = [
  'app-clienta.gov.uk'
  'app-clientb.gov.uk'
]
