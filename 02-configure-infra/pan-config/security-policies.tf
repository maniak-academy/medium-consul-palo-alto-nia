

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


