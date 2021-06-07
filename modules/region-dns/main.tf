resource "google_dns_record_set" "region-bastion" {
  project      = var.project
  name         = "bastion.${var.region}.${var.dnszone}"
  type         = "A"
  ttl          = 60
  managed_zone = var.zone-name
  rrdatas      = [var.bastion-ip]
}

resource "google_dns_record_set" "region-lb" {
  project      = var.project
  name         = "lb.${var.region}.${var.dnszone}"
  type         = "A"
  ttl          = 60
  managed_zone = var.zone-name
  rrdatas      = [var.lb-ip]
}

resource "google_dns_record_set" "region-consul" {
  project      = var.project
  name         = "consul.${var.region}.${var.dnszone}"
  type         = "A"
  ttl          = 60
  managed_zone = var.zone-name
  rrdatas      = [var.glb-ip]
}

resource "google_dns_record_set" "region-nomad" {
  project      = var.project
  name         = "nomad.${var.region}.${var.dnszone}"
  type         = "A"
  ttl          = 60
  managed_zone = var.zone-name
  rrdatas      = [var.glb-ip]
}

resource "google_dns_record_set" "region-vault" {
  project      = var.project
  name         = "vault.${var.region}.${var.dnszone}"
  type         = "A"
  ttl          = 60
  managed_zone = var.zone-name
  rrdatas      = [var.glb-ip]
}
