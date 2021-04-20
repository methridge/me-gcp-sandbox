output "region-1-consul" {
  value = trimsuffix("https://${google_dns_record_set.region-1-consul.name}", ".")
}

output "region-1-nomad" {
  value = trimsuffix("https://${google_dns_record_set.region-1-nomad.name}", ".")
}

output "region-1-vault" {
  value = trimsuffix("https://${google_dns_record_set.region-1-vault.name}", ".")
}
