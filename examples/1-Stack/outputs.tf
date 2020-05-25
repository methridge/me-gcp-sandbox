output us-central1-bastion-dns {
  value = google_dns_record_set.bastion-central1.name
}

output us-central1-bastion-ip {
  value = module.us-central1-region-stack.region-bastion-ip
}

output us-central1-lb-ip {
  value = module.us-central1-region-stack.region-lb-ip
}

output us-central1-lb-dns {
  value = google_dns_record_set.lb-central1.name
}
