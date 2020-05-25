output "region-bastion-ip" {
  value = google_compute_instance.region_bastion.network_interface.0.access_config.0.nat_ip
}

output "region-lb-ip" {
  value = google_compute_address.region-pub-ip.address
}
