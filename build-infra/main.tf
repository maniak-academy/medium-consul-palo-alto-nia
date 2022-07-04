module "network" {
  source = "./network"
}

module "vault" {
  source           = "./vault"
  resourcename     = module.network.resource_group_name
  resourcelocation = module.network.resource_group_location
  vault_subnet     = module.network.shared_svcs_subnets[1]
  pa_password      = module.pan-os.pa_password
  
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
}

module "app" {
  source           = "./app"
  resourcename     = module.network.resource_group_name
  resourcelocation = module.network.resource_group_location
  app_subnet       = module.network.app_subnet
  untrusted_subnet = module.network.untrusted_subnet
  consul_server_ip       = module.consul.consul_ip
  privateipfwnic2        = module.pan-os.privateipfwnic2
  privateipfwnic3        = module.pan-os.privateipfwnic3

}

# module "boundary" {
#   source              = "./boundary"
#   resourcename     = module.network.resource_group_name
#   resourcelocation = module.network.resource_group_location
#   controller_vm_count = 1
#   worker_vm_count     = 1
#   boundary_version    = "0.9.0"
#   shared_subnet    = module.network.shared_svcs_subnets[0]
#   mgmt_subnet      = module.network.mgmt_subnet
#   my_ip = "76.68.107.212"
# }