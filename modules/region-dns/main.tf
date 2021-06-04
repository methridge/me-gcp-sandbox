
resource "google_dns_record_set" "region-1-bastion" {
  project      = var.project
  name         = "bastion.${var.region}.${var.dnszone}"
  type         = "A"
  ttl          = 60
  managed_zone = var.zone-name
  rrdatas      = [var.bastion-ip]
}

resource "google_dns_record_set" "region-1-lb" {
  project      = var.project
  name         = "lb.${var.region}.${var.dnszone}"
  type         = "A"
  ttl          = 60
  managed_zone = var.zone-name
  rrdatas      = [var.lb-ip]
}

resource "google_dns_record_set" "region-1-consul" {
  project      = var.project
  name         = "consul.${var.region}.${var.dnszone}"
  type         = "A"
  ttl          = 60
  managed_zone = var.zone-name
  rrdatas      = [var.glb-ip]
}

resource "google_dns_record_set" "region-1-nomad" {
  project      = var.project
  name         = "nomad.${var.region}.${var.dnszone}"
  type         = "A"
  ttl          = 60
  managed_zone = var.zone-name
  rrdatas      = [var.glb-ip]
}

resource "google_dns_record_set" "region-1-vault" {
  project      = var.project
  name         = "vault.${var.region}.${var.dnszone}"
  type         = "A"
  ttl          = 60
  managed_zone = var.zone-name
  rrdatas      = [var.glb-ip]
}
