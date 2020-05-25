output sandbox-dnszone-dns-name {
  value = google_dns_managed_zone.sandbox-zone.dns_name
}

output sandbox-dnszone-name {
  value = google_dns_managed_zone.sandbox-zone.name
}
