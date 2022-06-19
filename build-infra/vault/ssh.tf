resource "tls_private_key" "vault" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_ssh_public_key" "vault" {
  name                = "vault"
  location            = "East US"
  resource_group_name = var.resourcename
  public_key          = tls_private_key.vault.public_key_openssh
}

resource "null_resource" "key" {
  provisioner "local-exec" {
    command = "echo \"${tls_private_key.vault.private_key_pem}\" > ${azurerm_ssh_public_key.vault.name}.pem"
  }

  provisioner "local-exec" {
    command = "chmod 600 *.pem"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f *.pem"
  }

}
