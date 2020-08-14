output "region-bastion-ip" {
  value = google_compute_instance.region_bastion.network_interface.0.access_config.0.nat_ip
}

output "region-lb-ip" {
  value = google_compute_address.region-pub-ip.address
}

output "vault_ca_key_pem" {
  value = module.region_vault_tls.vault_ca_key_pem
}

output "vault_ca_pem" {
  value = module.region_vault_tls.vault_ca_pem
}

output "vault_server_key_pem" {
  value = module.region_vault_tls.vault_server_key_pem
}

output "vault_server_pem" {
  value = module.region_vault_tls.vault_server_pem
}
