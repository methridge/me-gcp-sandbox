# output "region-1-bastion-dns" {
#   value = google_dns_record_set.region-1-bastion.name
# }

# output "region-1-bastion-ip" {
#   value = module.region-1-stack.region-bastion-ip
# }

# output "region-1-lb-ip" {
#   value = module.region-1-stack.region-lb-ip
# }

# output "region-1-lb-dns" {
#   value = google_dns_record_set.region-1-lb.name
# }

# output "region-1-glb-ip" {
#   value = module.region-1-stack.region-lb-global-ip
# }

output "region-1-consul" {
  value = trimsuffix("https://${google_dns_record_set.region-1-consul.name}", ".")
}

output "region-1-nomad" {
  value = trimsuffix("https://${google_dns_record_set.region-1-nomad.name}", ".")
}

output "region-1-vault" {
  value = trimsuffix("https://${google_dns_record_set.region-1-vault.name}", ".")
}
