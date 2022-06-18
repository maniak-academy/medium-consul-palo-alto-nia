
resource "azurerm_public_ip" "vault" {
  name                = "vault-ip"
  location            = var.resourcelocation
  resource_group_name = var.resourcename
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "vault" {
  name                = "vault-nic"
  location            = var.resourcelocation
  resource_group_name = var.resourcename

  ip_configuration {
    name                          = "configuration"
    subnet_id                     = var.vault_subnet
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb" "vault" {
  name                = "vault-lb"
  location            = var.resourcelocation
  resource_group_name = var.resourcename

  sku = "Standard"

  frontend_ip_configuration {
    name                 = "configuration"
    public_ip_address_id = azurerm_public_ip.vault.id
  }
}

resource "azurerm_lb_backend_address_pool" "vault" {
  loadbalancer_id     = azurerm_lb.vault.id
  name                = "BackEndAddressPool"
}

resource "azurerm_network_interface_backend_address_pool_association" "vault" {
  network_interface_id    = azurerm_network_interface.vault.id
  ip_configuration_name   = "configuration"
  backend_address_pool_ids = azurerm_lb_backend_address_pool.vault.id
}

resource "azurerm_lb_probe" "vault" {
  loadbalancer_id     = azurerm_lb.vault.id
  name                = "vault-http"
  port                = 8200
}

resource "azurerm_lb_rule" "vault" {
  loadbalancer_id                = azurerm_lb.vault.id
  name                           = "vault"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 8200
  frontend_ip_configuration_name = "configuration"
  probe_id                       = azurerm_lb_probe.vault.id
  backend_address_pool_id        = azurerm_lb_backend_address_pool.vault.id
}


resource "azurerm_linux_virtual_machine" "vault" {
  name                  = "vault-vm"
  location            = var.resourcelocation
  resource_group_name = var.resourcename
  network_interface_ids = [azurerm_network_interface.vault.id]
  size                  = "Standard_DS1_v2"

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  custom_data    = file("${path.module}/scripts/vault.sh")

  computer_name                   = "vault-vm"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.vault.public_key_openssh
  }

  tags = {
    environment = "staging"
  }
}


resource "azurerm_network_security_group" "vault" {
  name                = "vault-nsg"
  location            = var.resourcelocation
  resource_group_name = var.resourcename

  security_rule {
    name                       = "allow-ssh-all"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-vault-http-all"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8200"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

resource "azurerm_network_interface_security_group_association" "vault" {
  network_interface_id      = azurerm_network_interface.vault.id
  network_security_group_id = azurerm_network_security_group.vault.id
}
