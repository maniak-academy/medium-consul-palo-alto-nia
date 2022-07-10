resource "tls_private_key" "dbout" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_ssh_public_key" "dbout" {
  name                = "dbout"
  location            = "East US"
  resource_group_name = var.resource_group_name
  public_key          = tls_private_key.dbout.public_key_openssh
}

resource "null_resource" "dboutkey" {
  provisioner "local-exec" {
    command = "echo \"${tls_private_key.dbout.private_key_pem}\" > ${azurerm_ssh_public_key.dbout.name}.pem"
  }

  provisioner "local-exec" {
    command = "chmod 600 *.pem"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f *.pem"
  }

}
