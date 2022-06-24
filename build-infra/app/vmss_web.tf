resource "azurerm_linux_virtual_machine_scale_set" "web" {
  depends_on = [var.privateipfwnic3]
  name                            = "web-vmss"
  location                        = var.resourcelocation
  resource_group_name             = var.resourcename
  sku                             = "Standard_F2"
  instances                       = var.web_count
  admin_username                  = "adminuser"
  custom_data                     = base64encode(templatefile("${path.module}/templates/web_server.sh", { consul_server_ip = var.consul_server_ip }))
  disable_password_authentication = true

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.web.public_key_openssh
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name                      = "web-vms-netprofile"
    primary                   = true
    network_security_group_id = azurerm_network_security_group.webserver-sg.id

    ip_configuration {
      name      = "Web-IPConfiguration"
      subnet_id = var.untrusted_subnet
      primary   = true

    }
  }
}


resource "azurerm_network_security_group" "webserver-sg" {
  depends_on = [time_sleep.wait_30_seconds]
  name                = "webserver-security-group"
  location                        = var.resourcelocation
  resource_group_name             = var.resourcename

  security_rule {
    name                       = "HTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8500"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "RPC"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8300"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Serf"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8301"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "SSH"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}
