output "jumpserver-ip" {
  value = module.network.bastion_ip
}
output "vault_lb" {
  value = "http://${module.vault.vault_lb}"
}
output "consul_lb" {
  value = "http://${module.consul.consul_lb}"
}
output "pa_username" {
  value = module.pan-os.pa_username
}

output "pa_password" {
  value = module.pan-os.pa_password
}