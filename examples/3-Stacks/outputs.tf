output "region-1-consul" {
  value = trimsuffix("https://${google_dns_record_set.region-1-consul.name}", ".")
}

output "region-1-nomad" {
  value = trimsuffix("https://${google_dns_record_set.region-1-nomad.name}", ".")
}

output "region-1-vault" {
  value = trimsuffix("https://${google_dns_record_set.region-1-vault.name}", ".")
}

output "region-2-consul" {
  value = trimsuffix("https://${google_dns_record_set.region-2-consul.name}", ".")
}

output "region-2-nomad" {
  value = trimsuffix("https://${google_dns_record_set.region-2-nomad.name}", ".")
}

output "region-2-vault" {
  value = trimsuffix("https://${google_dns_record_set.region-2-vault.name}", ".")
}

output "region-3-consul" {
  value = trimsuffix("https://${google_dns_record_set.region-3-consul.name}", ".")
}

output "region-3-nomad" {
  value = trimsuffix("https://${google_dns_record_set.region-3-nomad.name}", ".")
}

output "region-3-vault" {
  value = trimsuffix("https://${google_dns_record_set.region-3-vault.name}", ".")
}
