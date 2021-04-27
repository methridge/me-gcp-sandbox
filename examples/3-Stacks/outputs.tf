# output "region-1-bastion-dns" {
#   value = google_dns_record_set.bastion-region-1.name
# }

# output "region-1-bastion-ip" {
#   value = module.region-1-stack.region-bastion-ip
# }

# output "region-1-lb-ip" {
#   value = module.region-1-stack.region-lb-ip
# }

# output "region-1-lb-dns" {
#   value = google_dns_record_set.lb-region-1.name
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

# output "region-2-bastion-dns" {
#   value = google_dns_record_set.bastion-region-2.name
# }

# output "region-2-bastion-ip" {
#   value = module.region-2-stack.region-bastion-ip
# }

# output "region-2-lb-ip" {
#   value = module.region-2-stack.region-lb-ip
# }

# output "region-2-lb-dns" {
#   value = google_dns_record_set.lb-region-2.name
# }

# output "region-2-glb-ip" {
#   value = module.region-2-stack.region-lb-global-ip
# }

output "region-2-consul" {
  value = trimsuffix("https://${google_dns_record_set.region-2-consul.name}", ".")
}

output "region-2-nomad" {
  value = trimsuffix("https://${google_dns_record_set.region-2-nomad.name}", ".")
}

output "region-2-vault" {
  value = trimsuffix("https://${google_dns_record_set.region-2-vault.name}", ".")
}

# output "region-3-bastion-dns" {
#   value = google_dns_record_set.bastion-region-3.name
# }

# output "region-3-bastion-ip" {
#   value = module.region-3-stack.region-bastion-ip
# }

# output "region-3-lb-ip" {
#   value = module.region-3-stack.region-lb-ip
# }

# output "region-3-lb-dns" {
#   value = google_dns_record_set.lb-region-3.name
# }

# output "region-3-glb-ip" {
#   value = module.region-3-stack.region-lb-global-ip
# }

output "region-3-consul" {
  value = trimsuffix("https://${google_dns_record_set.region-3-consul.name}", ".")
}

output "region-3-nomad" {
  value = trimsuffix("https://${google_dns_record_set.region-3-nomad.name}", ".")
}

output "region-3-vault" {
  value = trimsuffix("https://${google_dns_record_set.region-3-vault.name}", ".")
}
