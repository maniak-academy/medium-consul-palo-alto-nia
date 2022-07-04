# Create postgresql server


resource "random_id" "suffix" {
  byte_length = 2
}

resource "random_integer" "password-length" {
  min = 12
  max = 25
}

resource "random_password" "boundarypassword" {
  length           = random_integer.password-length.result
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  special          = true
  override_special = "_%!"
}

# You need to use a GP size or better to support the virtual
# Network rules. Basic version of Azure Postgres doesn't support it
resource "azurerm_postgresql_server" "boundary" {
  name                = local.pg_name
  location            = var.resourcelocation
  resource_group_name = var.resourcename

  administrator_login          = var.db_username
  administrator_login_password = random_password.boundarypassword.result

  sku_name   = "GP_Gen5_2"
  version    = "11"
  storage_mb = 51200

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  ssl_enforcement_enabled          = true
  ssl_minimal_tls_version_enforced = "TLS1_2"

}

#Lock down access to only the controller subnet
resource "azurerm_postgresql_virtual_network_rule" "vnet" {
  name                = "postgresql-vnet-rule"
  resource_group_name = var.resourcename
  server_name         = azurerm_postgresql_server.boundary.name
  subnet_id           = var.shared_subnet

  # Setting this to true for now, probably not necessary
  ignore_missing_vnet_service_endpoint = true
}
