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

data "google_netblock_ip_ranges" "gcp_ranges" {}

resource "google_compute_firewall" "lb-healthchecks" {
  name          = "${var.namespace}-lb-healthcheck-firewall"
  network       = data.terraform_remote_state.vpc.outputs.sandbox-network
  source_ranges = concat([data.terraform_remote_state.vpc.outputs.sandbox-subnet-region-1-cidr], var.healthcheck_ips)

  allow {
    protocol = "tcp"
  }
}

module "external-services" {
  source = "github.com/hashicorp/is-terraform-google-tfe-standalone//modules/external-services"

  namespace   = var.namespace
  network     = data.terraform_remote_state.vpc.outputs.sandbox-network
  credentials = var.credentials
  labels      = var.labels
}

module "configs" {
  source = "github.com/hashicorp/is-terraform-google-tfe-standalone//modules/configs"

  license_file        = var.tfe_license_file
  hostname            = "${var.subdomain}.${var.hostname}"
  postgres_config     = module.external-services.postgres_config
  object_store_config = module.external-services.object_storage_config
  add_bash_debug      = true
}

module "tfe" {
  source = "github.com/hashicorp/is-terraform-google-tfe-standalone//modules/tfe"

  namespace      = var.namespace
  region         = var.region
  startup_script = module.configs.startup_script
  labels         = var.labels
  # auto_healing_enabled = false

  instance_config = {
    machine_type   = "n1-standard-2"
    image_family   = "rhel-7"
    image_project  = "gce-uefi-images"
    boot_disk_size = 40
    type           = "pd-ssd"
  }

  networking_config = {
    network    = data.terraform_remote_state.vpc.outputs.sandbox-network
    subnetwork = data.terraform_remote_state.vpc.outputs.sandbox-subnet-region-1
  }
}

module "load-balancer" {
  source = "github.com/hashicorp/is-terraform-google-tfe-standalone//modules/load-balancer"

  namespace      = var.namespace
  instance_group = module.tfe.instance_group
  cert           = google_compute_ssl_certificate.default.self_link
  ip_allow_list  = var.public_ip_allowlist
}
