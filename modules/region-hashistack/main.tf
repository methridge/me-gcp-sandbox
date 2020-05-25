terraform {
  required_version = ">= 0.12.24"
}

data "google_compute_zones" "zones" {
  project = var.project
  region  = var.region
}

# data "google_netblock_ip_ranges" "gcp_ranges" {}

###
### Region Bastion Host
###
resource "google_compute_instance" "region_bastion" {
  name                    = "${var.region}-sandbox-bastion"
  machine_type            = var.machine_type
  project                 = var.project
  zone                    = data.google_compute_zones.zones.names[0]
  metadata_startup_script = data.template_file.region_bastion_startup_script.rendered
  tags                    = var.custom_tags
  boot_disk {
    initialize_params {
      image = var.image
    }
  }
  network_interface {
    subnetwork = var.subnetwork
    access_config {
      // Ephemeral IP
    }
  }
  service_account {
    email  = null
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}

data "template_file" "region_bastion_startup_script" {
  template = file("${path.module}/templates/bastion.sh.tmpl")
  vars = {
    consul_cluster_tag_name = "${var.region}-consul-servers"
  }
}

###
### Consul Cluster
###
module "region_consul_cluster" {
  source                        = "../consul-cluster"
  gcp_project_id                = var.project
  gcp_region                    = var.region
  cluster_name                  = "${var.region}-consul-cluster"
  cluster_tag_name              = "${var.region}-consul-servers"
  machine_type                  = var.machine_type
  cluster_size                  = var.consul_cluster_size
  source_image                  = var.image
  startup_script                = data.template_file.region-consul-server-startup-script.rendered
  network_name                  = var.network
  subnetwork_name               = var.subnetwork
  allowed_inbound_tags_http_api = var.custom_tags
  allowed_inbound_tags_dns      = var.custom_tags
  custom_tags                   = var.custom_tags
  instance_group_target_pools   = [module.region-consul-lb.target_pool]
}

data "template_file" "region-consul-server-startup-script" {
  template = file("${path.module}/templates/consul-server.sh.tmpl")
  vars = {
    cluster_name   = "${var.region}-consul-servers"
    consul_wan_tag = var.consul_wan_tag
  }
}

###
### Nomad Server Cluster
###
module "region_nomad_servers" {
  source                      = "../nomad-cluster"
  gcp_region                  = var.region
  gcp_project_id              = var.project
  cluster_name                = "${var.region}-nomad-server-cluster"
  cluster_size                = var.nomad_server_cluster_size
  cluster_tag_name            = "${var.region}-nomad-servers"
  machine_type                = var.machine_type
  network_name                = var.network
  subnetwork_name             = var.subnetwork
  source_image                = var.image
  startup_script              = data.template_file.region_startup_script_nomad_server.rendered
  custom_tags                 = compact(concat(var.custom_tags, [var.nomad_server_join_tag]))
  allowed_inbound_tags_http   = var.custom_tags
  allowed_inbound_tags_rpc    = var.custom_tags
  allowed_inbound_tags_serf   = var.custom_tags
  instance_group_target_pools = [module.region-nomad-lb.target_pool]
}

data "template_file" "region_startup_script_nomad_server" {
  template = file("${path.module}/templates/nomad-server.sh.tmpl")
  vars = {
    num_servers                    = var.nomad_server_cluster_size
    consul_server_cluster_tag_name = "${var.region}-consul-servers"
    nomad_server_join_tag          = var.nomad_server_join_tag
    nomad_acl_enabled              = var.nomad_acl_enabled
  }
}

module "region_nomad_clients" {
  source                      = "../nomad-cluster"
  gcp_region                  = var.region
  gcp_project_id              = var.project
  cluster_name                = "${var.region}-nomad-client-cluster"
  cluster_size                = var.nomad_client_cluster_size
  cluster_tag_name            = "${var.region}-nomad-clients"
  machine_type                = var.machine_type
  network_name                = var.network
  subnetwork_name             = var.subnetwork
  source_image                = var.image
  startup_script              = data.template_file.region_startup_script_nomad_client.rendered
  custom_tags                 = var.custom_tags
  allowed_inbound_tags_http   = var.custom_tags
  allowed_inbound_tags_rpc    = var.custom_tags
  allowed_inbound_tags_serf   = var.custom_tags
  instance_group_target_pools = [module.region-fabio-lb.target_pool, module.region-fabio-admin-lb.target_pool]
}

data "template_file" "region_startup_script_nomad_client" {
  template = file("${path.module}/templates/nomad-client.sh.tmpl")
  vars = {
    consul_server_cluster_tag_name = "${var.region}-consul-servers"
    nomad_acl_enabled              = var.nomad_acl_enabled
  }
}

###
### Vault Cluster
###
data "google_compute_default_service_account" "vault_test" {
  project = var.project
}

resource "random_id" "vault_id" {
  byte_length = 4
}

resource "google_kms_key_ring" "region_vault_key_ring" {
  project  = var.project
  name     = "vault-${var.region}-keyring-${random_id.vault_id.hex}"
  location = var.region
}

resource "google_kms_crypto_key" "region_crypto_key" {
  name            = "vault-key-primary"
  key_ring        = google_kms_key_ring.region_vault_key_ring.self_link
  rotation_period = "100000s"
}

resource "google_kms_crypto_key_iam_binding" "region_crypto_key_iam" {
  crypto_key_id = google_kms_crypto_key.region_crypto_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members = [
    "serviceAccount:${data.google_compute_default_service_account.vault_test.email}",
  ]
}

module "region_vault_cluster" {
  source                          = "../vault-cluster"
  network_name                    = var.network
  subnetwork_name                 = var.subnetwork
  gcp_project_id                  = var.project
  gcp_region                      = var.region
  cluster_name                    = "${var.region}-vault-cluster"
  cluster_size                    = var.vault_cluster_size
  cluster_tag_name                = "${var.region}-vault-servers"
  machine_type                    = var.machine_type
  source_image                    = var.image
  startup_script                  = data.template_file.region_startup_script_vault.rendered
  allowed_inbound_cidr_blocks_api = var.allowed_ips
  allowed_inbound_tags_api        = var.custom_tags
  custom_tags                     = var.custom_tags
  service_account_email           = data.google_compute_default_service_account.vault_test.email
  service_account_scopes          = ["cloud-platform"]
  instance_group_target_pools     = [module.region-vault-lb.target_pool]
}

data "template_file" "region_startup_script_vault" {
  template = file("${path.module}/templates/vault-server.sh.tmpl")
  vars = {
    consul_cluster_tag_name           = "${var.region}-consul-servers"
    vault_auto_unseal_key_project_id  = var.project
    vault_auto_unseal_key_region      = var.region
    vault_auto_unseal_key_ring        = google_kms_key_ring.region_vault_key_ring.name
    vault_auto_unseal_crypto_key_name = google_kms_crypto_key.region_crypto_key.name
  }
}

###
### Load Balancer
###
resource "google_compute_address" "region-pub-ip" {
  name    = "${var.region}-pub-ip"
  project = var.project
  region  = var.region
}

module "region-consul-lb" {
  source     = "github.com/GoogleCloudPlatform/terraform-google-lb"
  project    = var.project
  region     = var.region
  name       = "${var.region}-consul-lb"
  network    = var.network
  ip_address = google_compute_address.region-pub-ip.address
  health_check = {
    check_interval_sec  = 10
    healthy_threshold   = 5
    timeout_sec         = 5
    unhealthy_threshold = 10
    port                = 8500
    request_path        = "/v1/operator/autopilot/health"
    host                = "localhost"
  }
  service_port = 8500
  target_tags  = ["${var.region}-consul-servers"]
  allowed_ips  = var.allowed_ips
}

module "region-vault-lb" {
  source     = "github.com/GoogleCloudPlatform/terraform-google-lb"
  project    = var.project
  region     = var.region
  name       = "${var.region}-vault-lb"
  network    = var.network
  ip_address = google_compute_address.region-pub-ip.address
  health_check = {
    check_interval_sec  = 10
    healthy_threshold   = 5
    timeout_sec         = 5
    unhealthy_threshold = 10
    port                = 8200
    request_path        = "/v1/sys/health?uninitcode=200"
    host                = "localhost"
  }
  service_port = 8200
  target_tags  = ["${var.region}-vault-servers"]
  allowed_ips  = var.allowed_ips
}

module "region-nomad-lb" {
  source     = "github.com/GoogleCloudPlatform/terraform-google-lb"
  project    = var.project
  region     = var.region
  name       = "${var.region}-nomad-lb"
  network    = var.network
  ip_address = google_compute_address.region-pub-ip.address
  health_check = {
    check_interval_sec  = 10
    healthy_threshold   = 5
    timeout_sec         = 5
    unhealthy_threshold = 10
    port                = 4646
    request_path        = "/v1/agent/health"
    host                = "localhost"
  }
  service_port = 4646
  target_tags  = ["${var.region}-nomad-servers"]
  allowed_ips  = var.allowed_ips
}

module "region-fabio-lb" {
  source     = "github.com/GoogleCloudPlatform/terraform-google-lb"
  project    = var.project
  region     = var.region
  name       = "${var.region}-fabio-lb"
  network    = var.network
  ip_address = google_compute_address.region-pub-ip.address
  health_check = {
    check_interval_sec  = 10
    healthy_threshold   = 5
    timeout_sec         = 5
    unhealthy_threshold = 10
    port                = 9998
    request_path        = "/health"
    host                = "localhost"
  }
  service_port = 9999
  target_tags  = ["${var.region}-fabio-clients"]
  allowed_ips  = var.allowed_ips
}

module "region-fabio-admin-lb" {
  source     = "github.com/GoogleCloudPlatform/terraform-google-lb"
  project    = var.project
  region     = var.region
  name       = "${var.region}-fabio-admin-lb"
  network    = var.network
  ip_address = google_compute_address.region-pub-ip.address
  health_check = {
    check_interval_sec  = 10
    healthy_threshold   = 5
    timeout_sec         = 5
    unhealthy_threshold = 10
    port                = 9998
    request_path        = "/health"
    host                = "localhost"
  }
  service_port = 9998
  target_tags  = ["${var.region}-fabio-clients"]
  allowed_ips  = var.allowed_ips
}
