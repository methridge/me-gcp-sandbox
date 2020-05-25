provider "google" {
  version     = "~> 3.19"
  credentials = file(var.creds)
}

module "vpc" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 2.3"
  description  = "${var.username} Sandbox Network"
  project_id   = var.project
  network_name = "${var.username}-sandbox-network"

  subnets = [
    {
      subnet_name           = "${var.username}-sandbox-subnet-west1"
      subnet_ip             = var.subnet-west1
      subnet_region         = "us-west1"
      subnet_private_access = "true"
      description           = "US West 1 region Sandbox subnet"
    },
    {
      subnet_name           = "${var.username}-sandbox-subnet-central1"
      subnet_ip             = var.subnet-central1
      subnet_region         = "us-central1"
      subnet_private_access = "true"
      description           = "US Central 1 region Sandbox subnet"
    },
    {
      subnet_name           = "${var.username}-sandbox-subnet-east1"
      subnet_ip             = var.subnet-east1
      subnet_region         = "us-east1"
      subnet_private_access = "true"
      description           = "US East 1 region Sandbox subnet"
    }
  ]

  routes = [
    {
      name              = "egress-internet"
      description       = "route through IGW to access internet"
      destination_range = "0.0.0.0/0"
      tags              = "egress-inet"
      next_hop_internet = "true"
    }
  ]
}

module "us-west1-cloud_router" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 0.1"
  project = var.project
  network = module.vpc.network_name
  region  = "us-west1"
  name    = "${var.username}-sandbox-us-west1-router"
}

module "us-west1-cloud-nat" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "~> 1.3.0"
  project_id = var.project
  router     = module.us-west1-cloud_router.router.name
  region     = "us-west1"
  name       = "${var.username}-sandbox-us-west1-cloud-nat"
}

module "us-central1-cloud_router" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 0.1"
  project = var.project
  network = module.vpc.network_name
  region  = "us-central1"
  name    = "${var.username}-sandbox-us-central1-router"
}

module "us-central1-cloud-nat" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "~> 1.3.0"
  project_id = var.project
  router     = module.us-central1-cloud_router.router.name
  region     = "us-central1"
  name       = "${var.username}-sandbox-us-central1-cloud-nat"
}

module "us-east1-cloud_router" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 0.1"
  project = var.project
  network = module.vpc.network_name
  region  = "us-east1"
  name    = "${var.username}-sandbox-us-east1-router"
}

module "us-east1-cloud-nat" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "~> 1.3.0"
  project_id = var.project
  router     = module.us-east1-cloud_router.router.name
  region     = "us-east1"
  name       = "${var.username}-sandbox-us-east1-cloud-nat"
}

# data "google_netblock_ip_ranges" "gcp_ranges" {}

resource "google_compute_firewall" "default" {
  name    = "${var.username}-sandbox-firewall"
  project = var.project
  network = module.vpc.network_name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  source_ranges = var.admin_ip
  # source_ranges = concat(
  #   var.admin_ip,
  #   data.google_netblock_ip_ranges.gcp_ranges.cidr_blocks_ipv4
  # )

  source_tags = ["${var.username}-sandbox"]
}
