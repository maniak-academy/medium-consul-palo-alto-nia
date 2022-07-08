data "terraform_remote_state" "build-infra" {
  backend = "local"

  config = {
    path = "../build-infra/terraform.tfstate"
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

# NAT Rule

resource "panos_nat_rule_group" "app" {
  rule {
    name = "web_app"
    original_packet {
      source_zones          = ["public"]
      destination_zone      = "public"
      source_addresses      = ["any"]
      destination_addresses = ["10.1.0.5"]
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
          #address = data.terraform_remote_state.build-infra.outputs.web-lb
          address = "10.3.1.4"
        }
      }
    }
  }
}

# Security Rule


resource "panos_security_rule_group" "allow_app_traffic" {
  rule {
    name                  = "Allow web to talk to secure"
    source_zones          = ["public"]
    source_addresses      = ["any"]
    source_users          = ["any"]
    destination_zones     = ["private"]
    destination_addresses = ["any"]
    applications          = ["any"]
    services              = ["any"]
    categories            = ["any"]
    action                = "allow"
  }
}
