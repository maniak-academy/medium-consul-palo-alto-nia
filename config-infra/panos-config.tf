# terraform {
#   required_providers {
#     panos = {
#       source = "PaloAltoNetworks/panos"
#       version = "1.10.1"
#     }
#   }
# }

# provider "panos" {
#   hostname = azurerm_public_ip.PublicIP_0.ip_address
#   username = var.adminUsername
#   password = random_password.pafwpassword.result
# }



# # Virtual router

# resource "panos_virtual_router" "vr1" {
#   depends_on = [
#     azurerm_virtual_machine.PAN_FW_FW
#   ]
#   vsys = "vsys1"
#   name = "vr1"
#   interfaces = [
#     panos_ethernet_interface.ethernet1_1.name,
#     panos_ethernet_interface.ethernet1_2.name,
#     panos_ethernet_interface.ethernet1_3.name
#   ]
# }

# resource "panos_static_route_ipv4" "default_route" {
#   name           = "default"
#   virtual_router = panos_virtual_router.vr1.name
#   destination    = "0.0.0.0/0"
#   next_hop       = "10.3.2.1"
#   interface      = panos_ethernet_interface.ethernet1_1.name
# }

# # Service Object for port 9090

# resource "panos_service_object" "service-9090" {
#     name = "service-9090"
#     vsys = "vsys1"
#     protocol = "tcp"
#     destination_port = "9090"
# }

# # Management interface profile

# resource "panos_management_profile" "allow_ping_mgmt_profile" {
#   name = "allow-ping-ssh"
#   ping = true
#   ssh = true
# }


# # Untrust

# resource "panos_ethernet_interface" "ethernet1_1" {
#   vsys               = "vsys1"
#   name               = "ethernet1/1"
#   mode               = "layer3"
#   enable_dhcp        = true
#   management_profile = "allow-ping"
#   comment            = "Internet interface"
# }

# resource "panos_zone" "internet_zone" {
#   name = "Internet"
#   mode = "layer3"
# }

# resource "panos_zone_entry" "internet_zone_ethernet1_1" {
#   zone      = panos_zone.internet_zone.name
#   mode      = panos_zone.internet_zone.mode
#   interface = panos_ethernet_interface.ethernet1_1.name
# }


# # Untrust

# resource "panos_ethernet_interface" "ethernet1_2" {
#   vsys               = "vsys1"
#   name               = "ethernet1/2"
#   mode               = "layer3"
#   enable_dhcp        = true
#   management_profile = "allow-ping"
#   comment            = "DMZ interface"
# }

# resource "panos_zone" "untrust_zone" {
#   name = "untrusted"
#   mode = "layer3"
# }

# resource "panos_zone_entry" "untrust_zone_ethernet1_2" {
#   zone      = panos_zone.untrust_zone.name
#   mode      = panos_zone.untrust_zone.mode
#   interface = panos_ethernet_interface.ethernet1_2.name
# }


# # Application

# resource "panos_ethernet_interface" "ethernet1_3" {
#   vsys               = "vsys1"
#   name               = "ethernet1/3"
#   mode               = "layer3"
#   enable_dhcp        = true
#   management_profile = "allow-ping"
#   comment            = "Application interface"
# }

# resource "panos_zone" "app_zone" {
#   name = "Application"
#   mode = "layer3"
# }

# resource "panos_zone_entry" "app_zone_ethernet1_3" {
#   zone      = panos_zone.app_zone.name
#   mode      = panos_zone.app_zone.mode
#   interface = panos_ethernet_interface.ethernet1_3.name
# }

# # Dynamic Address Group
# resource "panos_address_group" "cts-addr-grp-web" {
#     name = "cts-addr-grp-web"
#     description = "Consul Web Servers"
#     dynamic_match = "web"
# #    dynamic_match = "'web' and 'app'"  # Example of multi-tag
# }

# # Dynamic Address Group
# resource "panos_address_group" "cts-addr-grp-app" {
#     name = "cts-addr-app-web"
#     description = "Consul app Servers"
#     dynamic_match = "app"
# #    dynamic_match = "'web' and 'app'"  # Example of multi-tag
# }


# # NAT Rule Specific


# resource "panos_nat_rule_group" "app" {
#   rule {
#     name = "web_app"
#     original_packet {
#       source_zones          = ["Internet"]
#       destination_zone      = "Internet"
#       source_addresses      = ["any"]
#       destination_addresses = ["10.3.2.5"]
#     }
#     translated_packet {
#       source {
#         dynamic_ip_and_port {
#           interface_address {
#             interface = panos_ethernet_interface.ethernet1_2.name
#           }
#         }
#       }
#       destination {
#         static_translation {
#           address = "10.3.3.4"
#         }
#       }
#     }
#   }
# }


# #NAT OUT
# resource "panos_nat_rule_group" "egree-nat" {
#   rule {
#     name          = "egress-nat"
#     audit_comment = "Ticket 12345"
#     original_packet {
#       source_zones          = [panos_zone.app_zone.name, panos_zone.untrust_zone.name]
#       destination_zone      = panos_zone.internet_zone.name
#       destination_interface = panos_ethernet_interface.ethernet1_1.name
#       source_addresses      = ["any"]
#       destination_addresses = ["any"]
#     }
#     translated_packet {
#       source {
#         dynamic_ip_and_port {
#           interface_address {
#             interface = panos_ethernet_interface.ethernet1_1.name
#           }
#         }
#       }
#       destination {}
#     }
#   }
# }
# # Security Rule



# resource "panos_security_rule_group" "allow_app_traffic" {
#   rule {
#     name                  = "Allow traffic to BIG-IP"
#     source_zones          = ["Internet"]
#     source_addresses      = ["any"]
#     source_users          = ["any"]
#     hip_profiles          = ["any"]
#     destination_zones     = ["DMZ"]
#     destination_addresses = ["10.3.2.5"]
#     applications          = ["any"]
#     services              = ["service-http", "service-https", "service-9090"]
#     categories            = ["any"]
#     action                = "allow"
#     description           = "Allow app traffic from Internet to BIG-IP"
#   }
# }
