data "terraform_remote_state" "environment" {
  backend = "local"

  config = {
    path = "../01-deploy-infra/terraform.tfstate"
  }
}


module "front-web-app" {
  source = "./front-web-app"
  resource_group_name = data.terraform_remote_state.environment.outputs.azurerm_resource_group
  location = data.terraform_remote_state.environment.outputs.location
  owner = data.terraform_remote_state.environment.outputs.owner
  web_subnet     = data.terraform_remote_state.environment.outputs.app_network_web_subnet
  consul_server_ip       = data.terraform_remote_state.environment.outputs.consul_ip
  web-id = data.terraform_remote_state.environment.outputs.web-id
  web_count = var.web_count
}

module "database-backend" {
  source = "./database-backend"
  resource_group_name = data.terraform_remote_state.environment.outputs.azurerm_resource_group
  location = data.terraform_remote_state.environment.outputs.location
  owner = data.terraform_remote_state.environment.outputs.owner
  db_subnet     = data.terraform_remote_state.environment.outputs.app_network_db_subnet
  consul_server_ip       = data.terraform_remote_state.environment.outputs.consul_ip

}
