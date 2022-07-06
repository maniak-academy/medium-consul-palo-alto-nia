
# Create the shared services network

module "shared-svcs-network" {
  source              = "Azure/network/azurerm"
  vnet_name           = "shared-svcs-vnet"
  resource_group_name = var.resource_group_name
  address_space       = "10.2.0.0/16"
  subnet_prefixes     = ["10.2.0.0/24", "10.2.1.0/24", "10.2.2.0/24"]
  subnet_names        = ["Boundary", "Vault", "Consul"]

  tags = {
    owner = var.owner
  }
  # depends_on = [
  #   azurerm_resource_group.this
  # ]
}


# create the peering between teh shared network to the secure network where pan is located.


resource "azurerm_virtual_network_peering" "sharedtoprivate" {
  name                      = "sharedtoprivate"
  resource_group_name     = var.resource_group_name
  virtual_network_name      = "shared-svcs-vnet"
  remote_virtual_network_id = module.vnet.virtual_network_id
}

resource "azurerm_virtual_network_peering" "privatetoshared" {
  name                      = "privatetoshared"
  resource_group_name     = var.resource_group_name
  virtual_network_name      = var.virtual_network_name
  remote_virtual_network_id = module.shared-svcs-network.vnet_id
}


# Create the app-network 

module "app-network" {
  source              = "Azure/network/azurerm"
  vnet_name           = "app-network"
  resource_group_name = var.resource_group_name
  address_space       = "10.3.0.0/16"
  subnet_prefixes     = ["10.3.0.0/24", "10.3.1.0/24"]
  subnet_names        = ["WEB", "DB"]

  tags = {
    owner = var.owner
  }
  depends_on = [
    module.vnet
  ]
}

# create the peering between teh app network to the secure network where pan is located.

resource "azurerm_virtual_network_peering" "appTOprivate" {
  name                      = "appTOprivate"
  resource_group_name     = var.resource_group_name
  virtual_network_name      = "app-network"
  remote_virtual_network_id = module.vnet.virtual_network_id
  depends_on = [
    module.app-network
  ]
}

resource "azurerm_virtual_network_peering" "privateTOapp" {
  name                      = "privateTOapp"
  resource_group_name     = var.resource_group_name
  virtual_network_name      = var.virtual_network_name
  remote_virtual_network_id = module.app-network.vnet_id
}

# Generate a random password.
resource "random_password" "this" {
  length           = 16
  min_lower        = 16 - 4
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  special          = true
  override_special = "_%@"
}
# Create the network required for the topology.
module "vnet" {
  source = "../../modules/vnet"

  virtual_network_name    = var.virtual_network_name
  location                = var.location
  resource_group_name     = var.resource_group_name
  address_space           = var.address_space
  network_security_groups = var.network_security_groups
  route_tables            = var.route_tables
  subnets                 = var.subnets
  tags                    = var.vnet_tags
  # depends_on = [
  #   azurerm_resource_group.this
  # ]
}



# Allow inbound access to Management subnet.
resource "azurerm_network_security_rule" "mgmt" {
  name                        = "vmseries-mgmt-allow-inbound"
  resource_group_name         = var.resource_group_name
  network_security_group_name = "sg-mgmt"
  access                      = "Allow"
  direction                   = "Inbound"
  priority                    = 1000
  protocol                    = "*"
  source_port_range           = "*"
  source_address_prefixes     = var.allow_inbound_mgmt_ips
  destination_address_prefix  = "*"
  destination_port_range      = "*"

  depends_on = [module.vnet]
}

# Create public IPs for the Internet-facing data interfaces so they could talk outbound.
resource "azurerm_public_ip" "public" {
  for_each = var.vmseries

  name                = "${var.name_prefix}${each.key}-public"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.enable_zones ? var.avzones : null
  # depends_on = [
  #   azurerm_resource_group.this
  # ]
}

# The Inbound Load Balancer for handling the traffic from the Internet.
module "inbound_lb" {
  source = "../../modules/loadbalancer"

  name                              = var.inbound_lb_name
  location                          = var.location
  resource_group_name               = var.resource_group_name
  frontend_ips                      = var.frontend_ips
  enable_zones                      = var.enable_zones
  avzones                           = var.avzones
  network_security_group_name       = "sg-public"
  network_security_allow_source_ips = coalescelist(var.allow_inbound_data_ips, var.allow_inbound_mgmt_ips)
  # depends_on = [
  #   azurerm_resource_group.this
  # ]
}

# The Outbound Load Balancer for handling the traffic from the private networks.
module "outbound_lb" {
  source = "../../modules/loadbalancer"

  name                = var.outbound_lb_name
  location            = var.location
  resource_group_name = var.resource_group_name
  enable_zones        = var.enable_zones
  avzones             = var.avzones
  frontend_ips = {
    outbound = {
      subnet_id                     = lookup(module.vnet.subnet_ids, "subnet-private", null)
      private_ip_address_allocation = "Static"
      private_ip_address            = var.olb_private_ip
      zones                         = var.enable_zones ? var.avzones : null # For the regions without AZ support.
      rules = {
        HA_PORTS = {
          port     = 0
          protocol = "All"
        }
      }
    }
  }
}

# # The storage account for VM-Series initialization.
module "bootstrap" {
  source = "../../modules/bootstrap"

  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_name = var.storage_account_name
  storage_share_name   = var.storage_share_name
  # files                = var.files
}

# Common VM-Series for handling:
#   - inbound traffic from the Internet
#   - outbound traffic to the Internet
#   - internal traffic (also known as "east-west" traffic)
module "common_vmseries" {
  source = "../../modules/vmseries"

  for_each = var.vmseries

  location            = var.location
  resource_group_name = var.resource_group_name
  name                = "${var.name_prefix}${each.key}"
  avzone              = try(each.value.avzone, 1)
  username            = var.username
  password            = coalesce(var.password, random_password.this.result)
  img_version         = var.common_vmseries_version
  img_sku             = var.common_vmseries_sku
  vm_size             = var.common_vmseries_vm_size
  tags                = var.common_vmseries_tags
  enable_zones        = var.enable_zones
  bootstrap_options = join(",",
    [
      "storage-account=${module.bootstrap.storage_account.name}",
      "access-key=${module.bootstrap.storage_account.primary_access_key}",
      "file-share=${module.bootstrap.storage_share.name}",
      "share-directory=None"
  ])
  interfaces = [
    {
      name                = "${each.key}-mgmt"
      subnet_id           = lookup(module.vnet.subnet_ids, "subnet-mgmt", null)
      create_public_ip    = true
      enable_backend_pool = false
    },
    {
      name                 = "${each.key}-public"
      subnet_id            = lookup(module.vnet.subnet_ids, "subnet-public", null)
      public_ip_address_id = azurerm_public_ip.public[each.key].id
      lb_backend_pool_id   = module.inbound_lb.backend_pool_id
      enable_backend_pool  = true
    },
    {
      name                = "${each.key}-private"
      subnet_id           = lookup(module.vnet.subnet_ids, "subnet-private", null)
      lb_backend_pool_id  = module.outbound_lb.backend_pool_id
      enable_backend_pool = true

      # Optional static private IP
      private_ip_address = try(each.value.trust_private_ip, null)
    },
  ]

  diagnostics_storage_uri = module.bootstrap.storage_account.primary_blob_endpoint

  depends_on = [module.bootstrap]
}
