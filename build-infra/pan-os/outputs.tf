output "FirewallIP" {
  value = azurerm_public_ip.PublicIP_0.ip_address
}

output "FirewallIPURL" {
  value = azurerm_public_ip.PublicIP_0.ip_address
}

output "FirewallFQDN" {
  value = azurerm_public_ip.PublicIP_0.fqdn
}

output "WebIP" {
  value = azurerm_public_ip.PublicIP_1.ip_address
}

output "WebFQDN" {
  value = azurerm_public_ip.PublicIP_1.fqdn
}

output "pa_username" {
  value = var.adminUsername
}

output "pa_password" {
  value = random_password.pafwpassword.result
}