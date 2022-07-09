
output "web-lb" {
  value = azurerm_lb.web.private_ip_address
}
output "web-id" {
  value = azurerm_lb_backend_address_pool.web.id
}