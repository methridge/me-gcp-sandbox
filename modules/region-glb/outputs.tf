output "region-lb-global-ip" {
  value = google_compute_global_address.region-global-pub-ip.address
}
