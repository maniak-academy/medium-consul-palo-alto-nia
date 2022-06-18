resource "tls_private_key" "bastion" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_ssh_public_key" "bastion" {
  name                = "bastion"
  location            = "East US"
  resource_group_name = azurerm_resource_group.consulnetworkautomation.name
  public_key          = tls_private_key.bastion.public_key_openssh
}

resource "null_resource" "key" {
  provisioner "local-exec" {
    command = "echo \"${tls_private_key.bastion.private_key_pem}\" > ${azurerm_ssh_public_key.bastion.name}.pem"
  }

  provisioner "local-exec" {
    command = "chmod 600 *.pem"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f *.pem"
  }

}
