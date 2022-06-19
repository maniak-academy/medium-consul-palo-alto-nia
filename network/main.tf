
resource "random_string" "participant" {
  length  = 4
  special = false
  upper   = false
  numeric = false
}

resource "azurerm_resource_group" "consulnetworkautomation" {
  name     = "consul-na-${random_string.participant.result}"
  location = "East US"
}

resource "random_password" "vm-password" {
  length           = 16
  min_upper        = 2
  min_lower        = 2
  min_special      = 2
  numeric          = true
  special          = true
  override_special = "!@#$%&"
}

module "shared-svcs-network" {
  source              = "Azure/network/azurerm"
  vnet_name           = "shared-svcs-vnet"
  resource_group_name = azurerm_resource_group.consulnetworkautomation.name
  address_space       = "10.2.0.0/16"
  subnet_prefixes     = ["10.2.0.0/24", "10.2.1.0/24", "10.2.2.0/24"]
  subnet_names        = ["SharedServices", "Vault", "Consul"]

  tags = {
    owner = "sebastian@maniak.io"
  }
}

module "app-network" {
  source              = "Azure/network/azurerm"
  resource_group_name = azurerm_resource_group.consulnetworkautomation.name
  vnet_name           = "app-vnet"
  address_space       = "10.3.0.0/16"
  subnet_prefixes     = ["10.3.1.0/24", "10.3.2.0/24", "10.3.3.0/24", "10.3.4.0/24"]
  subnet_names        = ["MGMT", "INTERNET", "UNTRUSTED", "APP"]

  tags = {
    owner = "sebastian@maniak.io"
  }
}

resource "azurerm_public_ip" "bastion" {
  name                = "bastion-ip"
  location            = azurerm_resource_group.consulnetworkautomation.location
  resource_group_name = azurerm_resource_group.consulnetworkautomation.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "bastion" {
  name                = "bastion-nic"
  location            = azurerm_resource_group.consulnetworkautomation.location
  resource_group_name = azurerm_resource_group.consulnetworkautomation.name

  ip_configuration {
    name                          = "configuration"
    subnet_id                     = module.shared-svcs-network.vnet_subnets[0]
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bastion.id
  }
}

resource "azurerm_linux_virtual_machine" "bastion" {
  name                  = "bastion-vm"
  location              = azurerm_resource_group.consulnetworkautomation.location
  resource_group_name   = azurerm_resource_group.consulnetworkautomation.name
  network_interface_ids = [azurerm_network_interface.bastion.id]
  size                  = "Standard_DS1_v2"

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  os_disk {
    name                 = "myOsDisk${random_string.participant.result}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  computer_name                   = "bastion-vm"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.bastion.public_key_openssh
  }

  tags = {
    environment = "staging"
  }
}

resource "azurerm_network_security_group" "bastion" {
  name                = "bastion-nsg"
  location            = azurerm_resource_group.consulnetworkautomation.location
  resource_group_name = azurerm_resource_group.consulnetworkautomation.name

  # Allow SSH traffic in from Internet to public subnet.
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
}

resource "azurerm_network_interface_security_group_association" "bastion" {
  network_interface_id      = azurerm_network_interface.bastion.id
  network_security_group_id = azurerm_network_security_group.bastion.id
}

resource "azurerm_virtual_network_peering" "shared-app" {
  name                      = "SharedToapp"
  resource_group_name       = azurerm_resource_group.consulnetworkautomation.name
  virtual_network_name      = "shared-svcs-vnet"
  remote_virtual_network_id = module.app-network.vnet_id
}

resource "azurerm_virtual_network_peering" "app-shared" {
  name                      = "appToShared"
  resource_group_name       = azurerm_resource_group.consulnetworkautomation.name
  virtual_network_name      = "app-vnet"
  remote_virtual_network_id = module.shared-svcs-network.vnet_id
}