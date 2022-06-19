


output "resource_group_name" {
  value = azurerm_resource_group.consulnetworkautomation.name
}

output "resource_group_location" {
  value = azurerm_resource_group.consulnetworkautomation.location
}

output "shared_svcs_vnet" {
  value = module.shared-svcs-network.vnet_id
}

output "shared_svcs_subnets" {
  value = module.shared-svcs-network.vnet_subnets
}

output "mgmt_subnet" {
  value = module.app-network.vnet_subnets[0]
}

output "internet_subnet" {
  value = module.app-network.vnet_subnets[1]
}

output "untrusted_subnet" {
  value = module.app-network.vnet_subnets[2]
}

output "app_subnet" {
  value = module.app-network.vnet_subnets[3]
}
output "secure_subnet" {
  value = module.app-network.vnet_subnets[4]
}

output "bastion_ip" {
  value = azurerm_public_ip.bastion.ip_address
}
output "bastion_ip_password" {
  value     = random_password.vm-password.result
  sensitive = true
}