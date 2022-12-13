data "terraform_remote_state" "environment" {
  backend = "local"

  config = {
    path = "../01-deploy-infra/terraform.tfstate"
  }
}

module "cts" {
  source = "./cts"
  resource_group_name = data.terraform_remote_state.environment.outputs.azurerm_resource_group
  location = data.terraform_remote_state.environment.outputs.location
  owner = data.terraform_remote_state.environment.outputs.owner
  consul_subnet     = data.terraform_remote_state.environment.outputs.shared_network_consul_subnets
  consul_server_ip       = data.terraform_remote_state.environment.outputs.consul_ip
  panos_mgmt_addr = data.terraform_remote_state.environment.outputs.paloalto_mgmt_ip
  panos_username = data.terraform_remote_state.environment.outputs.pa_username
}

