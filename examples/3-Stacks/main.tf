provider "google" {
  version     = "~> 3.19"
  credentials = file(var.creds)
}

data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "${path.module}/../Network/terraform.tfstate"
  }
}

data "terraform_remote_state" "dns" {
  backend = "local"

  config = {
    path = "${path.module}/../DNS-Zone/terraform.tfstate"
  }
}

# West Region
module "us-west1-region-stack" {
  source                = "../modules/region-hashistack"
  project               = var.project
  region                = "us-west1"
  image                 = data.google_compute_image.my_image.name
  machine_type          = var.machine_type
  network               = data.terraform_remote_state.vpc.outputs.sandbox-network
  subnetwork            = data.terraform_remote_state.vpc.outputs.sandbox-subnet-west1
  allowed_ips           = var.admin_ip
  custom_tags           = ["${var.username}-sandbox"]
  consul_wan_tag        = "us-central1-consul-servers"
  nomad_server_join_tag = "nomad-servers"
}

resource "google_dns_record_set" "bastion-west1" {
  project      = var.project
  name         = "bastion.us-west1.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
  type         = "A"
  ttl          = 60
  managed_zone = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  rrdatas      = [module.us-west1-region-stack.region-bastion-ip]
}

resource "google_dns_record_set" "lb-west1" {
  project      = var.project
  name         = "lb.us-west1.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
  type         = "A"
  ttl          = 60
  managed_zone = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  rrdatas      = [module.us-west1-region-stack.region-lb-ip]
}

# Central Region
module "us-central1-region-stack" {
  source                = "../modules/region-hashistack"
  project               = var.project
  region                = "us-central1"
  image                 = data.google_compute_image.my_image.name
  machine_type          = var.machine_type
  network               = data.terraform_remote_state.vpc.outputs.sandbox-network
  subnetwork            = data.terraform_remote_state.vpc.outputs.sandbox-subnet-central1
  allowed_ips           = var.admin_ip
  custom_tags           = ["${var.username}-sandbox"]
  consul_wan_tag        = "us-east1-consul-servers"
  nomad_server_join_tag = "nomad-servers"
}

resource "google_dns_record_set" "bastion-central1" {
  project      = var.project
  name         = "bastion.us-central1.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
  type         = "A"
  ttl          = 60
  managed_zone = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  rrdatas      = [module.us-central1-region-stack.region-bastion-ip]
}

resource "google_dns_record_set" "lb-central1" {
  project      = var.project
  name         = "lb.us-central1.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
  type         = "A"
  ttl          = 60
  managed_zone = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  rrdatas      = [module.us-central1-region-stack.region-lb-ip]
}

#East Region
module "us-east1-region-stack" {
  source                = "../modules/region-hashistack"
  project               = var.project
  region                = "us-east1"
  image                 = data.google_compute_image.my_image.name
  machine_type          = var.machine_type
  network               = data.terraform_remote_state.vpc.outputs.sandbox-network
  subnetwork            = data.terraform_remote_state.vpc.outputs.sandbox-subnet-east1
  allowed_ips           = var.admin_ip
  custom_tags           = ["${var.username}-sandbox"]
  consul_wan_tag        = "us-west1-consul-servers"
  nomad_server_join_tag = "nomad-servers"
}

resource "google_dns_record_set" "bastion-east1" {
  project      = var.project
  name         = "bastion.us-east1.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
  type         = "A"
  ttl          = 60
  managed_zone = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  rrdatas      = [module.us-east1-region-stack.region-bastion-ip]
}

resource "google_dns_record_set" "lb-east1" {
  project      = var.project
  name         = "lb.us-east1.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
  type         = "A"
  ttl          = 60
  managed_zone = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  rrdatas      = [module.us-east1-region-stack.region-lb-ip]
}
