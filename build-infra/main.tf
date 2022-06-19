module "network" {
  source = "./network"
}

module "vault" {
  source           = "./vault"
  resourcename     = module.network.resource_group_name
  resourcelocation = module.network.resource_group_location
  vault_subnet     = module.network.shared_svcs_subnets[1]
}

module "consul" {
  source           = "./consul"
  resourcename     = module.network.resource_group_name
  resourcelocation = module.network.resource_group_location
  consul_subnet    = module.network.shared_svcs_subnets[2]
}

module "pan-os" {
  source           = "./pan-os"
  resourcename     = module.network.resource_group_name
  resourcelocation = module.network.resource_group_location
  mgmt_subnet      = module.network.mgmt_subnet
  internet_subnet  = module.network.internet_subnet
  untrusted_subnet = module.network.untrusted_subnet
  app_subnet       = module.network.app_subnet
  secure_subnet    = module.network.secure_subnet
}