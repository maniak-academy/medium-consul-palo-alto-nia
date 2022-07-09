data "terraform_remote_state" "deploy-infra" {
  backend = "local"

  config = {
    path = "../01-deploy-infra/terraform.tfstate"
  }
}

#Virtual router

resource "panos_virtual_router" "vr1" {
  vsys = "vsys1"
  name = "vr1"
  interfaces = [
    panos_ethernet_interface.ethernet1_1.name,
    panos_ethernet_interface.ethernet1_2.name
  ]
}

resource "panos_static_route_ipv4" "default_route" {
  name           = "default"
  virtual_router = panos_virtual_router.vr1.name
  destination    = "0.0.0.0/0"
  next_hop       = "10.1.0.1"
  interface      = panos_ethernet_interface.ethernet1_1.name
}

#route to web and db network 
resource "panos_static_route_ipv4" "internal_route" {
  name           = "internal_route"
  virtual_router = panos_virtual_router.vr1.name
  destination    = "10.3.0.0/16"
  next_hop       = "10.1.1.1"
  interface      = panos_ethernet_interface.ethernet1_2.name
}

# Service Object for port 9090

resource "panos_service_object" "service-9090" {
    name = "service-9090"
    vsys = "vsys1"
    protocol = "tcp"
    destination_port = "9090"
}

# Management interface profile

resource "panos_management_profile" "allow_ping_mgmt_profile" {
  name = "allow-ping"
  ping = true
}


# public

resource "panos_ethernet_interface" "ethernet1_1" {
  vsys               = "vsys1"
  name               = "ethernet1/1"
  mode               = "layer3"
  enable_dhcp        = true
  management_profile = "allow-ping"
  comment            = "public interface"
  depends_on         = [panos_management_profile.allow_ping_mgmt_profile]
}

resource "panos_zone" "public_zone" {
  name = "public"
  mode = "layer3"
}

resource "panos_zone_entry" "public_zone_ethernet1_1" {
  zone      = panos_zone.public_zone.name
  mode      = panos_zone.public_zone.mode
  interface = panos_ethernet_interface.ethernet1_1.name
}


# Private

resource "panos_ethernet_interface" "ethernet1_2" {
  vsys               = "vsys1"
  name               = "ethernet1/2"
  mode               = "layer3"
  enable_dhcp        = true
  management_profile = "allow-ping"
  comment            = "private interface"
  depends_on         = [panos_management_profile.allow_ping_mgmt_profile]
}

resource "panos_zone" "private_zone" {
  name = "private"
  mode = "layer3"
}

resource "panos_zone_entry" "private_zone_ethernet1_2" {
  zone      = panos_zone.private_zone.name
  mode      = panos_zone.private_zone.mode
  interface = panos_ethernet_interface.ethernet1_2.name
}




# Dynamic Address Group
resource "panos_address_group" "cts-addr-grp-web" {
    name = "cts-addr-grp-web"
    description = "Consul Web Servers"
    dynamic_match = "web"
#    dynamic_match = "'web' and 'app'"  # Example of multi-tag
}

# Dynamic Address Group
resource "panos_address_group" "cts-addr-grp-db" {
    name = "cts-addr-grp-db"
    description = "Consul db Servers"
    dynamic_match = "db"
#    dynamic_match = "'web' and 'app'"  # Example of multi-tag
}


# NAT Rule

resource "panos_nat_rule_group" "app" {
  rule {
    name = "web_app"
    original_packet {
      source_zones          = ["public"]
      destination_zone      = "public"
      source_addresses      = ["any"]
      destination_addresses = [data.terraform_remote_state.deploy-infra.outputs.privateipfwnic1]
    }
    translated_packet {
      source {
        dynamic_ip_and_port {
          interface_address {
            interface = panos_ethernet_interface.ethernet1_2.name
          }
        }
      }
      destination {
        static_translation {
          address = data.terraform_remote_state.deploy-infra.outputs.web-lb
        }
      }
    }
  }
}

resource "panos_nat_rule_group" "egress-nat" {
  rule {
    name          = "egress-nat"
    audit_comment = "Ticket 12345"
    original_packet {
      source_zones          = [panos_zone.private_zone.name]
      destination_zone      = panos_zone.public_zone.name
      destination_interface = panos_ethernet_interface.ethernet1_1.name
      source_addresses      = ["any"]
      destination_addresses = ["any"]
    }
    translated_packet {
      source {
        dynamic_ip_and_port {
          interface_address {
            interface = panos_ethernet_interface.ethernet1_1.name
          }
        }
      }
      destination {}
    }
  }
}

# Security Rule


resource "panos_security_rule_group" "allow_app_traffic" {
  rule {
    name                  = "Allow public to talk to app"
    source_zones          = [panos_zone.public_zone.name]
    source_addresses      = ["any"]
    source_users          = ["any"]
    destination_zones     = [panos_zone.private_zone.name]
    destination_addresses = [data.terraform_remote_state.deploy-infra.outputs.privateipfwnic1]
    applications          = ["any"]
    services              = ["any"]
    categories            = ["any"]
    action                = "allow"
  }
}




resource "panos_security_rule_group" "egressout" {
  rule {
    name                  = "egressout"
    source_zones          = [panos_zone.private_zone.name]
    source_addresses      = ["any"]
    source_users          = ["any"]
    destination_zones     = [panos_zone.public_zone.name]
    destination_addresses = ["any"]
    applications          = ["any"]
    services              = ["any"]
    categories            = ["any"]
    action                = "allow"
  }
}


resource "panos_security_rule_group" "web-db-allow" {
  rule {
    name                  = "web-db-allow"
    source_zones          = [panos_zone.private_zone.name]
    source_addresses      = ["10.3.1.0/24"]
    source_users          = ["any"]
    destination_zones     = [panos_zone.private_zone.name]
    destination_addresses = ["10.3.2.0/24"]
    applications          = ["any"]
    services              = ["any"]
    categories            = ["any"]
    action                = "allow"
  }
}
