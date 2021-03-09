output "region-bastion-ip" {
  value = google_compute_instance.region_bastion.network_interface.0.access_config.0.nat_ip
}

output "region-lb-ip" {
  value = google_compute_address.region-pub-ip.address
}

# output "region-lb-global-ip" {
#   value = google_compute_global_address.region-global-pub-ip.address
# }

output "region-lb-global-ip" {
  value = module.global-https-lb.region-lb-global-ip
}
output "consul_server_key_pem" {
  value = module.region_consul_tls.consul_server_key_pem
}

output "consul_server_pem" {
  value = module.region_consul_tls.consul_server_pem
}

output "consul_client_key_pem" {
  value = module.region_consul_tls.consul_client_key_pem
}

output "consul_client_pem" {
  value = module.region_consul_tls.consul_client_pem
}

output "vault_server_key_pem" {
  value = module.region_vault_tls.vault_server_key_pem
}

output "vault_server_pem" {
  value = module.region_vault_tls.vault_server_pem
}
