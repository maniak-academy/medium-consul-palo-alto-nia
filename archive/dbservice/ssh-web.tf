resource "tls_private_key" "dbdemo" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_ssh_public_key" "dbdemo" {
  name                = "dbdemo"
  location            = "East US"
  resource_group_name = var.resource_group_name
  public_key          = tls_private_key.dbdemo.public_key_openssh
}

resource "null_resource" "dbdemokey" {
  provisioner "local-exec" {
    command = "echo \"${tls_private_key.dbdemo.private_key_pem}\" > ${azurerm_ssh_public_key.dbdemo.name}.pem"
  }

  provisioner "local-exec" {
    command = "chmod 600 *.pem"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f *.pem"
  }

}
