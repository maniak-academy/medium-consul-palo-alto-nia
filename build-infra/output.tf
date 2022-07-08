output "bastion-ip" {
  value = "ssh -i bastion.pem azureuser@${module.sharedservices.bastion_ip}"
}
output "vault_lb" {
  value = "http://${module.sharedservices.vault_lb}"
}
output "consul_lb" {
  value = "http://${module.sharedservices.consul_lb}"
}
output "pa_username" {
  value = module.pan-os.pa_username
}
output "pa_password" {
  value     = module.pan-os.pa_password
  sensitive = true
}
output "https_paloalto_mgmt_ip" {
  value = "https://${module.pan-os.FirewallIP}"
}
output "paloalto_mgmt_ip" {
  value = module.pan-os.FirewallIP
}

output "web-lb" {
  value = module.webservice.web-lb
}

output "WebFQDN" {
  value = "http://${module.pan-os.WebFQDN}"
  
}
# output "privateipfwnic2" {
#   value = module.pan-os.privateipfwnic2
# }
# output "privateipfwnic3" {
#   value = module.pan-os.privateipfwnic3
# }