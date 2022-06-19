resource "tls_private_key" "consul" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_ssh_public_key" "consul" {
  name                = "consul"
  location            = "East US"
  resource_group_name = var.resourcename
  public_key          = tls_private_key.consul.public_key_openssh
}

resource "null_resource" "key" {
  provisioner "local-exec" {
    command = "echo \"${tls_private_key.consul.private_key_pem}\" > ${azurerm_ssh_public_key.consul.name}.pem"
  }

  provisioner "local-exec" {
    command = "chmod 600 *.pem"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f *.pem"
  }

}
