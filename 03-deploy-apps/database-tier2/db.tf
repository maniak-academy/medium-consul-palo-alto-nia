
resource "random_string" "dboutparticipant" {
  length  = 4
  special = false
  upper   = false
  numeric = false
}

resource "azurerm_network_interface" "dbout" {
  name                = "dbout-nic"
  location              = var.location
  resource_group_name   = var.resource_group_name

  ip_configuration {
    name                          = "dbinternal"
    subnet_id                     = var.db_subnet
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "dbout" {
  name                  = "dbout-vm"
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.dbout.id]
  size                  = "Standard_DS1_v2"

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  os_disk {
    name                 = "dboutmyOsDisk${random_string.dboutparticipant.result}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  custom_data                     = base64encode(templatefile("${path.module}/scripts/juiceshop.sh", { 
    consul_server_ip = var.consul_server_ip,
    CONSUL_VERSION = "1.12.2" 
  }))


  computer_name                   = "dbout-vm"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.dbout.public_key_openssh
  }

  tags = {
    environment = "staging"
  }
}

resource "azurerm_network_interface_security_group_association" "dbout" {
  network_interface_id      = azurerm_network_interface.dbout.id
  network_security_group_id = azurerm_network_security_group.dboutserver-sg.id
}


resource "azurerm_network_security_group" "dboutserver-sg" {
  name                = "dboutserver-security-group"
  location                        = var.location
  resource_group_name             = var.resource_group_name

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
  security_rule {
    name                       = "dbout2"
    priority                   = 1007
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9094"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "juiceshop"
    priority                   = 1008
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
