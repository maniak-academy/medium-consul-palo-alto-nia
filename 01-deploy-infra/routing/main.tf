resource "azurerm_route_table" "web-route-to-fw" {
  name                = "web-route-to-fw"
  location            = var.location
  resource_group_name = var.resource_group_name

  route {
    name                   = "web-route-to-fw"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.1.1.5"
  }
  route {
    name                   = "web-route-to-db"
    address_prefix         = "10.3.2.0/24"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.1.1.5"
  }

  tags = {
    environment = "Production"
  }
}


resource "azurerm_subnet_route_table_association" "example2" {
 subnet_id                 = var.web_subnet
 route_table_id            = azurerm_route_table.web-route-to-fw.id
}



resource "azurerm_route_table" "db-route-to-fw" {
  name                = "db-route-to-fw"
  location            = var.location
  resource_group_name = var.resource_group_name

  route {
    name                   = "db-route-to-fw"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.1.1.5"
  }
  route {
    name                   = "db-route-to-web"
    address_prefix         = "10.3.1.0/24"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.1.1.5"
  }

  tags = {
    environment = "Production"
  }
}


resource "azurerm_subnet_route_table_association" "db-route-to-fw" {
 subnet_id                 = var.db_subnet
 route_table_id            = azurerm_route_table.db-route-to-fw.id
}

