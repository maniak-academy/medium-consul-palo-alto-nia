terraform {
  required_providers {
    panos = {
      source = "PaloAltoNetworks/panos"
      version = "1.10.3"
    }
  }
}

data "terraform_remote_state" "build-infra" {
  backend = "local"

  config = {
    path = "../build-infra/terraform.tfstate"
  }
}

provider "panos" {
  hostname = data.terraform_remote_state.build-infra.outputs.paloalto_mgmt_ip
  username = data.terraform_remote_state.build-infra.outputs.pa_username
  password = data.terraform_remote_state.build-infra.outputs.pa_password
}

module "pan-config" {
  source = "./pan-config"
}

module "vault" {
  source = "./vault"
}

# resource "null_resource" "pan" {
#   depends_on = [module.pan-config]

#   triggers = {
#     always_run = "${timestamp()}"
#   }

#   provisioner "local-exec" {
#     command = "/Users/sebbycorp/Documents/Projects/paloalto/medium-consul-palo-alto-nia/config-infra/panos_commit/panos-commit -config /Users/sebbycorp/Documents/Projects/paloalto/medium-consul-palo-alto-nia/config-infra/panos_commit/panos-commit.json -force"
#   }
# }
