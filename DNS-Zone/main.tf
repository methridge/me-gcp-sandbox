provider "google" {
  version     = ">= 3.19"
  credentials = file(var.creds)
}

resource "google_dns_managed_zone" "sandbox-zone" {
  project     = var.project
  name        = "${var.username}-sandbox-zone"
  dns_name    = var.zone_name
  description = "DNS zone for Sandbox"
}
