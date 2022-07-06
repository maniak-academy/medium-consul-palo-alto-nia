output "username" {
  description = "Initial administrative username to use for VM-Series."
  value       = var.username
}

output "password" {
  description = "Initial administrative password to use for VM-Series."
  value       = module.secure-infrastructure.password
  sensitive   = true
}

output "mgmt_ip_addresses" {
  description = "IP Addresses for VM-Series management (https or ssh)."
  value       = module.secure-infrastructure.mgmt_ip_addresses
}

 
output "frontend_ips" {
  description = "IP Addresses of the inbound load balancer."
  value       = module.secure-infrastructure.frontend_ips
}

output "vault_lb" {
  description = "Vault load balancer IP."
  value       = "http://${module.sharedservices-infrastructure.vault_lb}"
}
output "consul_lb" {
  description = "Consul load balancer IP."
  value       = "http://${module.sharedservices-infrastructure.consul_lb}"
}
