output region-1-bastion-dns {
  value = google_dns_record_set.bastion-region-1.name
}

output region-1-bastion-ip {
  value = module.region-1-stack.region-bastion-ip
}

output region-1-lb-ip {
  value = module.region-1-stack.region-lb-ip
}

output region-1-lb-dns {
  value = google_dns_record_set.lb-region-1.name
}

output region-2-bastion-dns {
  value = google_dns_record_set.bastion-region-2.name
}

output region-2-bastion-ip {
  value = module.region-2-stack.region-bastion-ip
}

output region-2-lb-ip {
  value = module.region-2-stack.region-lb-ip
}

output region-2-lb-dns {
  value = google_dns_record_set.lb-region-2.name
}

output region-3-bastion-dns {
  value = google_dns_record_set.bastion-region-3.name
}

output region-3-bastion-ip {
  value = module.region-3-stack.region-bastion-ip
}

output region-3-lb-ip {
  value = module.region-3-stack.region-lb-ip
}

output region-3-lb-dns {
  value = google_dns_record_set.lb-region-3.name
}
