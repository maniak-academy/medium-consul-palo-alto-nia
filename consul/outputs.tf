output "consul_lb" {
  value = azurerm_public_ip.consul.ip_address
}

output "consul_ip" {
  value = azurerm_network_interface.consul.private_ip_address
}
