

# Create the Resource Group.
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}


module "secure-infrastructure" {
    source = "./secure-infrastructure"
    owner = var.owner
    resource_group_name = azurerm_resource_group.this.name
    olb_private_ip = var.olb_private_ip
    storage_share_name = var.storage_share_name
    route_tables = var.route_tables
    network_security_groups = var.network_security_groups
    subnets = var.subnets
    address_space = var.address_space
    frontend_ips = var.frontend_ips
    vmseries = var.vmseries
    virtual_network_name = var.virtual_network_name
    allow_inbound_mgmt_ips = var.allow_inbound_mgmt_ips
    storage_account_name = var.storage_account_name
    common_vmseries_version = var.common_vmseries_version
    common_vmseries_sku = var.common_vmseries_sku
    depends_on = [
      azurerm_resource_group.this
    ]
}

module "sharedservices-infrastructure" {
    source = "./sharedservices-infrastructure"
    location = var.location
    owner = var.owner
    resource_group_name = azurerm_resource_group.this.name
    consul_subnet = module.secure-infrastructure.shared_svcs_subnets[2]
    vault_subnet = module.secure-infrastructure.shared_svcs_subnets[1]  
    depends_on = [
      azurerm_resource_group.this
    ]
}

module "app-infrastructure" {
    source = "./app-infrastructure"
    location = var.location
    owner = var.owner
    resource_group_name = azurerm_resource_group.this.name
    web_subnet = module.secure-infrastructure.app-network_subnets[1]
    db_subnet = module.secure-infrastructure.app-network_subnets[0]  
        depends_on = [
      azurerm_resource_group.this
    ]
}