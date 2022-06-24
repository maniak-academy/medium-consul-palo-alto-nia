
resource "null_resource" "previous" {}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [null_resource.previous]

  create_duration = "30s"
}

resource "azurerm_linux_virtual_machine_scale_set" "app" {
  depends_on = [var.privateipfwnic2]
  name                = "app-vmss"
  location            = var.resourcelocation
  resource_group_name = var.resourcename
  sku                 = "Standard_F2"
  instances           = var.app_count
  admin_username      = "adminuser"

  custom_data                     = base64encode(templatefile("${path.module}/templates/app_server.sh", { consul_server_ip = var.consul_server_ip, CONSUL_VERSION = "1.12.2", CTS_CONSUL_VERSION="0.6.0-beta1", CONSUL_URL="https://releases.hashicorp.com/consul-terraform-sync" }))
  disable_password_authentication = true

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.app.public_key_openssh
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
    name                      = "app-vms-netprofile"
    primary                   = true
    network_security_group_id = azurerm_network_security_group.app-sg.id

    ip_configuration {
      name      = "App-IPConfiguration"
      subnet_id = var.app_subnet
      primary   = true

    }
  }

}




resource "azurerm_network_security_group" "app-sg" {
  name                = "appserver-security-group"
  location            = var.resourcelocation
  resource_group_name = var.resourcename
  depends_on = [time_sleep.wait_30_seconds]

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
    name                       = "app"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9091"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "web"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9090"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
