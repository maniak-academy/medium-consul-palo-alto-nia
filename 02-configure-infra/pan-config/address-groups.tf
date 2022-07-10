

# Dynamic Address Group
resource "panos_address_group" "cts-addr-grp-web" {
    name = "cts-addr-grp-web"
    description = "Consul Web Servers"
    dynamic_match = "web"
#    dynamic_match = "'web' and 'app'"  # Example of multi-tag
}


# Dynamic Address Group
resource "panos_address_group" "cts-addr-grp-app" {
    name = "cts-addr-grp-app"
    description = "Consul app Servers"
    dynamic_match = "app"
#    dynamic_match = "'web' and 'app'"  # Example of multi-tag
}

# Dynamic Address Group
resource "panos_address_group" "cts-addr-grp-db" {
    name = "cts-addr-grp-db"
    description = "Consul db Servers"
    dynamic_match = "db"
#    dynamic_match = "'web' and 'app'"  # Example of multi-tag
}