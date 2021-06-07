output "region-bastion-dns" {
  value = module.region-dns.region-bastion-dns
}
output "region-bastion-ip" {
  value = google_compute_instance.region_bastion.network_interface.0.access_config.0.nat_ip
}

output "region-lb-dns" {
  value = module.region-dns.region-lb-dns
}
output "region-lb-ip" {
  value = google_compute_address.region-pub-ip.address
}

output "region-consul-dns" {
  value = module.region-dns.region-consul-dns
}

output "region-nomad-dns" {
  value = module.region-dns.region-nomad-dns
}

output "region-vault-dns" {
  value = module.region-dns.region-vault-dns
}

output "region-lb-global-ip" {
  value = module.global-https-lb.region-lb-global-ip
}
output "consul_server_key_pem" {
  value     = module.region_consul_tls.consul_server_key_pem
  sensitive = true
}

output "consul_server_pem" {
  value     = module.region_consul_tls.consul_server_pem
  sensitive = true
}

output "consul_client_key_pem" {
  value     = module.region_consul_tls.consul_client_key_pem
  sensitive = true
}

output "consul_client_pem" {
  value     = module.region_consul_tls.consul_client_pem
  sensitive = true
}

output "vault_server_key_pem" {
  value     = module.region_vault_tls.vault_server_key_pem
  sensitive = true
}

output "vault_server_pem" {
  value     = module.region_vault_tls.vault_server_pem
  sensitive = true
}
