resource "azurerm_route_table" "PAN_FW_RT_Trust" {
  name                = var.routeTableTrust
  location            = var.resourcelocation
  resource_group_name = var.resourcename

  route {
    name                   = "routeToTrust"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.3.1.5"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_route_table" "PAN_FW_RT_App" {
  name                = "routeToApp"
  location            = var.resourcelocation
  resource_group_name = var.resourcename

  route {
    name                   = "routeToApp"
    address_prefix         = "10.3.2.0/24"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.3.2.5"
  }

  route {
    name                   = "Web-default-route"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.3.2.5"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_route_table" "PAN_FW_RT_DMZ" {
  name                = "routeToDmz"
  location            = var.resourcelocation
  resource_group_name = var.resourcename

  route {
    name                   = "DMZ-to-Firewall-Web"
    address_prefix         = "10.3.1.0/24"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.3.1.5"
  }

  route {
    name                   = "DMZ-default-route"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.3.1.5"
  }

  tags = {
    environment = "Production"
  }
}
resource "azurerm_route_table" "PAN_FW_RT_Secure" {
  name                = "routeToSecure"
  location            = var.resourcelocation
  resource_group_name = var.resourcename

  route {
    name                   = "routeToSecure"
    address_prefix         = "10.3.5.0/24"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.3.5.5"
  }

  route {
    name                   = "secure-default-route"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.3.5.5"
  }

  tags = {
    environment = "Production"
  }
}


#resource "azurerm_subnet_route_table_association" "example2" {
#  subnet_id                 = azurerm_subnet.app_subnet.id
#  route_table_id            = azurerm_route_table.PAN_FW_RT_Trust.id
#}