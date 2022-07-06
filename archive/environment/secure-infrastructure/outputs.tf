output "username" {
  description = "Initial administrative username to use for VM-Series."
  value       = var.username
}

output "password" {
  description = "Initial administrative password to use for VM-Series."
  value       = coalesce(var.password, random_password.this.result)
  sensitive   = true
}

output "mgmt_ip_addresses" {
  description = "IP Addresses for VM-Series management (https or ssh)."
  value       = { for k, v in module.common_vmseries : k => v.mgmt_ip_address }
#  value       = module.common_vmseries.fw00.mgmt_ip_address
}


output "frontend_ips" {
  description = "IP Addresses of the inbound load balancer."
  value       = module.inbound_lb.frontend_ip_configs
}

output "shared_svcs_vnet" {
  value = module.shared-svcs-network.vnet_id
}

output "shared_svcs_subnets" {
  value = module.shared-svcs-network.vnet_subnets
}

output "app-network" {
  value = module.app-network.vnet_id
}

output "app-network_subnets" {
  value = module.app-network.vnet_subnets
}

# output "vault_lb" {
#   value = azurerm_public_ip.vault.ip_address
# }