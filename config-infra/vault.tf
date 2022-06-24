terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
      version = "3.7.0"
    }
  }
}


provider "vault" {
    address = "http://${azurerm_public_ip.vault.ip_address}"
    token = "root"
}

resource "vault_mount" "infrastructure" {
  path        = "net_infra"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine mount"
  depends_on = [
    azurerm_linux_virtual_machine.vault
  ]
}

resource "vault_kv_secret_v2" "net_infra" {
  mount                      = vault_mount.infrastructure.path
  name                       = "paloalto"
  cas                        = 1
  delete_all_versions        = true
  data_json                  = jsonencode(
  {
    panpassword       = var.pa_password
  }
  )
}
