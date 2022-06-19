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
  consul_subnet     = module.network.shared_svcs_subnets[2]
}

