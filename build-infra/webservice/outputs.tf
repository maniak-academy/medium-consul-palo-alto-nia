output "web-lb" {
  value = azurerm_lb.web.private_ip_address
}