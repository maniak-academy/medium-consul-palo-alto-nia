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

# resource "null_resource" "panos_config" {
#   depends_on = [module.panos-config]

#   triggers = {
#     always_run = "${timestamp()}"
#   }

#   provisioner "local-exec" {
#     command = "/root/terraform/panos_commit/panos-commit -config /root/terraform/panos_commit/panos-commit.json -force"
#   }
# }
