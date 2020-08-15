provider "google" {
  version     = ">= 3.19"
  credentials = file(var.creds)
}

module "vpc" {
  source       = "terraform-google-modules/network/google"
  version      = ">= 2.3"
  description  = "${var.username} Sandbox Network"
  project_id   = var.project
  network_name = "${var.username}-sandbox-network"

  subnets = [
    {
      subnet_name           = "${var.username}-sandbox-subnet-region-1"
      subnet_ip             = var.subnet-region-1
      subnet_region         = var.region-name-1
      subnet_private_access = "true"
      description           = "First region sandbox subnet"
    },
    {
      subnet_name           = "${var.username}-sandbox-subnet-region-2"
      subnet_ip             = var.subnet-region-2
      subnet_region         = var.region-name-2
      subnet_private_access = "true"
      description           = "Second region sandbox subnet"
    },
    {
      subnet_name           = "${var.username}-sandbox-subnet-region-3"
      subnet_ip             = var.subnet-region-3
      subnet_region         = var.region-name-3
      subnet_private_access = "true"
      description           = "Third region sandbox subnet"
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

module "first_region_cloud_router" {
  source  = "terraform-google-modules/cloud-router/google"
  version = ">= 0.1"
  project = var.project
  network = module.vpc.network_name
  region  = var.region-name-1
  name    = "${var.username}-sandbox-${var.region-name-1}-router"
}

module "first_region_cloud_nat" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = ">= 1.3.0"
  project_id = var.project
  router     = module.first_region_cloud_router.router.name
  region     = var.region-name-1
  name       = "${var.username}-sandbox-${var.region-name-1}-cloud-nat"
}

module "second_region_cloud_router" {
  source  = "terraform-google-modules/cloud-router/google"
  version = ">= 0.1"
  project = var.project
  network = module.vpc.network_name
  region  = var.region-name-2
  name    = "${var.username}-sandbox-${var.region-name-2}-router"
}

module "second_region_cloud_nat" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = ">= 1.3.0"
  project_id = var.project
  router     = module.second_region_cloud_router.router.name
  region     = var.region-name-2
  name       = "${var.username}-sandbox-${var.region-name-2}-cloud-nat"
}

module "third_region_cloud_router" {
  source  = "terraform-google-modules/cloud-router/google"
  version = ">= 0.1"
  project = var.project
  network = module.vpc.network_name
  region  = var.region-name-3
  name    = "${var.username}-sandbox-${var.region-name-3}-router"
}

module "third_region_cloud-nat" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = ">= 1.3.0"
  project_id = var.project
  router     = module.third_region_cloud_router.router.name
  region     = var.region-name-3
  name       = "${var.username}-sandbox-${var.region-name-3}-cloud-nat"
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
