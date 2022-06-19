output "jumpserver-ip" {
  value = module.network.bastion_ip
}
output "vault_lb" {
  value = module.vault.vault_lb
}
output "consul_lb" {
  value = module.consul.consul_lb
}