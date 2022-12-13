# Deploy cts

resource "random_string" "ctsparticipant" {
  length  = 4
  special = false
  upper   = false
  numeric = false
}
resource "azurerm_public_ip" "cts" {
  name                = "cts-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "cts" {
  name                = "cts-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ctsconfiguration"
    subnet_id                     = var.consul_subnet
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb" "cts" {
  name                = "cts-lb"
  location            = var.location
  resource_group_name = var.resource_group_name

  sku = "Standard"

  frontend_ip_configuration {
    name                 = "ctsconfiguration"
    public_ip_address_id = azurerm_public_ip.cts.id
  }
}

resource "azurerm_lb_backend_address_pool" "cts" {
  loadbalancer_id = azurerm_lb.cts.id
  name            = "ctsBackEndAddressPool"
}

resource "azurerm_network_interface_backend_address_pool_association" "cts" {
  network_interface_id    = azurerm_network_interface.cts.id
  ip_configuration_name   = "ctsconfiguration"
  backend_address_pool_id = azurerm_lb_backend_address_pool.cts.id
}

resource "azurerm_lb_probe" "cts" {
  loadbalancer_id = azurerm_lb.cts.id
  name            = "cts-http"
  port            = 22
}

resource "azurerm_lb_rule" "cts" {
  loadbalancer_id                = azurerm_lb.cts.id
  name                           = "cts"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "ctsconfiguration"
  probe_id                       = azurerm_lb_probe.cts.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.cts.id]
}


resource "azurerm_linux_virtual_machine" "cts" {
  name                  = "cts-vm"
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.cts.id]
  size                  = "Standard_DS1_v2"

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  os_disk {
    name                 = "ctsnmyOsDisk${random_string.ctsparticipant.result}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  custom_data = base64encode(templatefile("${path.module}/scripts/cts.sh", { 
    consul_server_ip = var.consul_server_ip,
    CONSUL_VERSION = "1.14.1" 
  }))

  computer_name                   = "cts-vm"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.cts.public_key_openssh
  }

  tags = {
    environment = "staging"
  }
}


resource "azurerm_network_security_group" "cts" {
  name                = "cts-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

   security_rule {
    name                       = "SSH-22"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
   security_rule {
    name                       = "cts"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "5140"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

resource "azurerm_network_interface_security_group_association" "cts" {
  network_interface_id      = azurerm_network_interface.cts.id
  network_security_group_id = azurerm_network_security_group.cts.id
    depends_on = [
    azurerm_linux_virtual_machine.cts
  ]
}


## SSH Key 

resource "tls_private_key" "cts" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_ssh_public_key" "cts" {
  name                = "cts"
  location            = var.location
  resource_group_name = var.resource_group_name
  public_key          = tls_private_key.cts.public_key_openssh
}

resource "null_resource" "ctskey" {
  provisioner "local-exec" {
    command = "echo \"${tls_private_key.cts.private_key_pem}\" > ${azurerm_ssh_public_key.cts.name}.pem"
  }

  provisioner "local-exec" {
    command = "chmod 600 *.pem"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f *.pem"
  }

}

