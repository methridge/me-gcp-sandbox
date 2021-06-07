output "region-bastion-dns" {
  value = google_dns_record_set.region-bastion.name
}

output "region-lb-dns" {
  value = google_dns_record_set.region-lb.name
}

output "region-consul-dns" {
  value = google_dns_record_set.region-consul.name
}

output "region-nomad-dns" {
  value = google_dns_record_set.region-nomad.name
}

output "region-vault-dns" {
  value = google_dns_record_set.region-vault.name
}
