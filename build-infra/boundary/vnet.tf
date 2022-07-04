
# Create Network Security Groups for subnets
resource "azurerm_network_security_group" "controller_net" {
  name                = local.controller_net_nsg
  location            = var.resourcelocation
  resource_group_name = var.resourcename
}

resource "azurerm_network_security_group" "worker_net" {
  name                = local.worker_net_nsg
  location            = var.resourcelocation
  resource_group_name = var.resourcename
}


# Create NSG associations
resource "azurerm_subnet_network_security_group_association" "controller" {
  subnet_id                 = var.shared_subnet
  network_security_group_id = azurerm_network_security_group.controller_net.id
  depends_on = [
    azurerm_linux_virtual_machine.controller
  ]
}

resource "azurerm_subnet_network_security_group_association" "worker" {
  subnet_id                 = var.shared_subnet
  network_security_group_id = azurerm_network_security_group.worker_net.id
    depends_on = [
    azurerm_linux_virtual_machine.worker
  ]
}

# Create Network Security Groups for NICs
# The associations are in the vm.tf file and remotehosts.tf file

resource "azurerm_network_security_group" "controller_nics" {
  name                = local.controller_nic_nsg
  location            = var.resourcelocation
  resource_group_name = var.resourcename
}

resource "azurerm_network_security_group" "worker_nics" {
  name                = local.worker_nic_nsg
  location            = var.resourcelocation
  resource_group_name = var.resourcename
}

# Create application security groups for controllers, workers, and backend
# The associations are in the vm.tf file and remotehosts.tf file

resource "azurerm_application_security_group" "controller_asg" {
  name                = local.controller_asg
  location            = var.resourcelocation
  resource_group_name = var.resourcename
}

resource "azurerm_application_security_group" "worker_asg" {
  name                = local.worker_asg
  location            = var.resourcelocation
  resource_group_name = var.resourcename
}
