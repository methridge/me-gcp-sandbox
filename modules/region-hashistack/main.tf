terraform {
  required_version = ">= 0.12.24"
}

data "google_compute_zones" "zones" {
  project = var.project
  region  = var.region
}

###
### Region Config Storage Bucket
###
resource "google_storage_bucket" "config_bucket" {
  name               = "${var.region}-config-bucket"
  location           = upper(var.region)
  force_destroy      = true
  project            = var.project
  bucket_policy_only = true
}

resource "google_storage_bucket_object" "config_files" {
  for_each = fileset("${path.module}/bucket-files", "*")
  name     = each.value
  bucket   = google_storage_bucket.config_bucket.name
  source   = "${path.module}/bucket-files/${each.value}"
}

###
### Region Bastion Host
###
resource "google_compute_instance" "region_bastion" {
  name                    = "${var.region}-sandbox-bastion"
  machine_type            = var.bastion_machine_type
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
    hashistack_image                  = var.hashistack_image
    prem_bucket                       = var.prem_bucket
    config_bucket                     = google_storage_bucket.config_bucket.name
    consul_mode                       = var.consul_mode
    consul_version                    = var.consul_version
    consul_ent                        = var.consul_ent
    consul_prem                       = var.consul_prem
    consul_cluster_tag_name           = "${var.region}-consul-servers"
    vault_mode                        = var.vault_mode
    vault_storage                     = var.vault_storage
    vault_version                     = var.vault_version
    vault_ent                         = var.vault_ent
    vault_prem                        = var.vault_prem
    vault_auto_unseal_key_project_id  = ""
    vault_auto_unseal_key_region      = ""
    vault_auto_unseal_key_ring        = ""
    vault_auto_unseal_crypto_key_name = ""
    nomad_mode                        = var.nomad_mode
    nomad_version                     = var.nomad_version
    nomad_ent                         = var.nomad_ent
    nomad_prem                        = var.nomad_prem
    nomad_num_servers                 = 0
    nomad_cluster_tag_name            = var.nomad_cluster_tag_name
    nomad_acl_enabled                 = var.nomad_acl_enabled
    consul_template_ver               = var.consul_template_ver
    envconsul_ver                     = var.envconsul_ver
    terraform_ver                     = var.terraform_ver
    elk_stack                         = var.elk_stack
  }
  depends_on = [module.region_consul_tls.consul_gossip_encryption_key]
}

###
### Consul Cluster
###

# Consul TLS
module "region_consul_tls" {
  source         = "../consul-tls"
  dc             = var.region
  config_bucket  = google_storage_bucket.config_bucket.name
  dnszone        = var.dnszone
  sandbox_ca_pem = var.sandbox_ca_pem
  sandbox_ca_key = var.sandbox_ca_key
}

resource "google_storage_bucket_object" "consul-master-token" {
  depends_on = [module.region_consul_tls]
  name       = "consul-tls/consul-master-token.txt"
  bucket     = google_storage_bucket.config_bucket.name
  content    = var.consul_token
}

resource "google_storage_bucket_object" "consul-gossip" {
  depends_on = [module.region_consul_tls]
  name       = "consul-tls/consul-gossip.txt"
  bucket     = google_storage_bucket.config_bucket.name
  content    = var.consul_gossip_key
}

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
    hashistack_image                  = var.hashistack_image
    prem_bucket                       = var.prem_bucket
    config_bucket                     = google_storage_bucket.config_bucket.name
    consul_mode                       = "server"
    consul_version                    = var.consul_version
    consul_ent                        = var.consul_ent
    consul_prem                       = var.consul_prem
    consul_cluster_tag_name           = "${var.region}-consul-servers"
    consul_cluster_wan_tag_name       = var.consul_wan_tag
    consul_primary_dc                 = var.consul_primary_dc
    vault_mode                        = var.vault_mode
    vault_storage                     = var.vault_storage
    vault_version                     = var.vault_version
    vault_ent                         = var.vault_ent
    vault_prem                        = var.vault_prem
    vault_auto_unseal_key_project_id  = ""
    vault_auto_unseal_key_region      = ""
    vault_auto_unseal_key_ring        = ""
    vault_auto_unseal_crypto_key_name = ""
    nomad_mode                        = var.nomad_mode
    nomad_version                     = var.nomad_version
    nomad_ent                         = var.nomad_ent
    nomad_prem                        = var.nomad_prem
    nomad_num_servers                 = 0
    nomad_cluster_tag_name            = var.nomad_cluster_tag_name
    nomad_acl_enabled                 = var.nomad_acl_enabled
    consul_template_ver               = var.consul_template_ver
    envconsul_ver                     = var.envconsul_ver
    terraform_ver                     = var.terraform_ver
    elk_stack                         = var.elk_stack
  }
  depends_on = [module.region_consul_tls.consul_gossip_encryption_key]
}

# ###
# ### Consul Config files
# ###
# module "consul_server_config" {
#   source                        = "../../../consul-config"
#   enable_node_metadata          = true
#   configure_autopilot           = true
#   autopilot_redundancy_zone_tag = "zone"
#   server                        = true
# }

# resource "google_storage_bucket_object" "consul_server_config_template" {
#   name    = "consul/${var.region}/consul-server.tmpl"
#   content = module.consul_server_config.config
#   bucket  = "sandbox-bin"
# }

# module "consul_client_config" {
#   source               = "../../../consul-config"
#   enable_node_metadata = true
# }

# resource "google_storage_bucket_object" "consul_client_config_template" {
#   name    = "consul/${var.region}/consul-client.tmpl"
#   content = module.consul_client_config.config
#   bucket  = "sandbox-bin"
# }

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
    hashistack_image                  = var.hashistack_image
    prem_bucket                       = var.prem_bucket
    config_bucket                     = google_storage_bucket.config_bucket.name
    consul_mode                       = var.consul_mode
    consul_version                    = var.consul_version
    consul_ent                        = var.consul_ent
    consul_prem                       = var.consul_prem
    consul_cluster_tag_name           = "${var.region}-consul-servers"
    vault_mode                        = var.vault_mode
    vault_storage                     = var.vault_storage
    vault_version                     = var.vault_version
    vault_ent                         = var.vault_ent
    vault_prem                        = var.vault_prem
    vault_auto_unseal_key_project_id  = ""
    vault_auto_unseal_key_region      = ""
    vault_auto_unseal_key_ring        = ""
    vault_auto_unseal_crypto_key_name = ""
    nomad_mode                        = "server"
    nomad_version                     = var.nomad_version
    nomad_ent                         = var.nomad_ent
    nomad_prem                        = var.nomad_prem
    nomad_num_servers                 = var.nomad_server_cluster_size
    nomad_cluster_tag_name            = var.nomad_cluster_tag_name
    nomad_acl_enabled                 = var.nomad_acl_enabled
    consul_template_ver               = var.consul_template_ver
    envconsul_ver                     = var.envconsul_ver
    terraform_ver                     = var.terraform_ver
    elk_stack                         = var.elk_stack
  }
  depends_on = [module.region_consul_tls.consul_gossip_encryption_key]
}

module "region_nomad_clients" {
  source                    = "../nomad-cluster"
  gcp_region                = var.region
  gcp_project_id            = var.project
  cluster_name              = "${var.region}-nomad-client-cluster"
  cluster_size              = var.nomad_client_cluster_size
  cluster_tag_name          = "${var.region}-nomad-clients"
  machine_type              = var.worker_machine_type
  network_name              = var.network
  subnetwork_name           = var.subnetwork
  source_image              = var.image
  startup_script            = data.template_file.region_startup_script_nomad_client.rendered
  custom_tags               = var.custom_tags
  allowed_inbound_tags_http = var.custom_tags
  allowed_inbound_tags_rpc  = var.custom_tags
  allowed_inbound_tags_serf = var.custom_tags
  instance_group_target_pools = [
    module.region-fabio-lb.target_pool,
    module.region-fabio-admin-lb.target_pool,
    module.region-traefik-lb.target_pool,
  module.region-traefik-admin-lb.target_pool]
}

data "template_file" "region_startup_script_nomad_client" {
  template = file("${path.module}/templates/nomad-client.sh.tmpl")
  vars = {
    hashistack_image                  = var.hashistack_image
    prem_bucket                       = var.prem_bucket
    config_bucket                     = google_storage_bucket.config_bucket.name
    consul_mode                       = var.consul_mode
    consul_version                    = var.consul_version
    consul_ent                        = var.consul_ent
    consul_prem                       = var.consul_prem
    consul_cluster_tag_name           = "${var.region}-consul-servers"
    vault_mode                        = var.vault_mode
    vault_storage                     = var.vault_storage
    vault_version                     = var.vault_version
    vault_ent                         = var.vault_ent
    vault_prem                        = var.vault_prem
    vault_auto_unseal_key_project_id  = ""
    vault_auto_unseal_key_region      = ""
    vault_auto_unseal_key_ring        = ""
    vault_auto_unseal_crypto_key_name = ""
    nomad_mode                        = "client"
    nomad_version                     = var.nomad_version
    nomad_ent                         = var.nomad_ent
    nomad_prem                        = var.nomad_prem
    nomad_num_servers                 = var.nomad_client_cluster_size
    nomad_cluster_tag_name            = var.nomad_cluster_tag_name
    nomad_acl_enabled                 = var.nomad_acl_enabled
    consul_template_ver               = var.consul_template_ver
    envconsul_ver                     = var.envconsul_ver
    terraform_ver                     = var.terraform_ver
    elk_stack                         = var.elk_stack
  }
  depends_on = [module.region_consul_tls.consul_gossip_encryption_key]
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

# Vault TLS
module "region_vault_tls" {
  source         = "../vault-tls"
  region         = var.region
  config_bucket  = google_storage_bucket.config_bucket.name
  dnszone        = var.dnszone
  sandbox_ca_pem = var.sandbox_ca_pem
  sandbox_ca_key = var.sandbox_ca_key
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
    hashistack_image                  = var.hashistack_image
    prem_bucket                       = var.prem_bucket
    config_bucket                     = google_storage_bucket.config_bucket.name
    consul_mode                       = var.consul_mode
    consul_version                    = var.consul_version
    consul_ent                        = var.consul_ent
    consul_prem                       = var.consul_prem
    consul_cluster_tag_name           = "${var.region}-consul-servers"
    vault_mode                        = "server"
    vault_storage                     = var.vault_storage
    vault_version                     = var.vault_version
    vault_ent                         = var.vault_ent
    vault_prem                        = var.vault_prem
    vault_auto_unseal_key_project_id  = var.project
    vault_auto_unseal_key_region      = var.region
    vault_auto_unseal_key_ring        = google_kms_key_ring.region_vault_key_ring.name
    vault_auto_unseal_crypto_key_name = google_kms_crypto_key.region_crypto_key.name
    nomad_mode                        = var.nomad_mode
    nomad_version                     = var.nomad_version
    nomad_ent                         = var.nomad_ent
    nomad_prem                        = var.nomad_prem
    nomad_num_servers                 = 0
    nomad_cluster_tag_name            = var.nomad_cluster_tag_name
    nomad_acl_enabled                 = var.nomad_acl_enabled
    consul_template_ver               = var.consul_template_ver
    envconsul_ver                     = var.envconsul_ver
    terraform_ver                     = var.terraform_ver
    elk_stack                         = var.elk_stack
  }
  depends_on = [module.region_consul_tls.consul_gossip_encryption_key]
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

module "region-traefik-lb" {
  source     = "github.com/GoogleCloudPlatform/terraform-google-lb"
  project    = var.project
  region     = var.region
  name       = "${var.region}-traefik-lb"
  network    = var.network
  ip_address = google_compute_address.region-pub-ip.address
  health_check = {
    check_interval_sec  = 10
    healthy_threshold   = 5
    timeout_sec         = 5
    unhealthy_threshold = 10
    port                = 8082
    request_path        = "/ping"
    host                = "localhost"
  }
  service_port = 8080
  target_tags  = ["${var.region}-traefik-clients"]
  allowed_ips  = var.allowed_ips
}

module "region-traefik-admin-lb" {
  source     = "github.com/GoogleCloudPlatform/terraform-google-lb"
  project    = var.project
  region     = var.region
  name       = "${var.region}-traefik-admin-lb"
  network    = var.network
  ip_address = google_compute_address.region-pub-ip.address
  health_check = {
    check_interval_sec  = 10
    healthy_threshold   = 5
    timeout_sec         = 5
    unhealthy_threshold = 10
    port                = 8082
    request_path        = "/ping"
    host                = "localhost"
  }
  service_port = 8081
  target_tags  = ["${var.region}-traefik-clients"]
  allowed_ips  = var.allowed_ips
}

module "region-traefik-grafana-lb" {
  source     = "github.com/GoogleCloudPlatform/terraform-google-lb"
  project    = var.project
  region     = var.region
  name       = "${var.region}-traefik-grafana-lb"
  network    = var.network
  ip_address = google_compute_address.region-pub-ip.address
  health_check = {
    check_interval_sec  = 10
    healthy_threshold   = 5
    timeout_sec         = 5
    unhealthy_threshold = 10
    port                = 8082
    request_path        = "/ping"
    host                = "localhost"
  }
  service_port = 3000
  target_tags  = ["${var.region}-traefik-clients"]
  allowed_ips  = var.allowed_ips
}

module "region-traefik-kibana-lb" {
  source     = "github.com/GoogleCloudPlatform/terraform-google-lb"
  project    = var.project
  region     = var.region
  name       = "${var.region}-traefik-kibana-lb"
  network    = var.network
  ip_address = google_compute_address.region-pub-ip.address
  health_check = {
    check_interval_sec  = 10
    healthy_threshold   = 5
    timeout_sec         = 5
    unhealthy_threshold = 10
    port                = 8082
    request_path        = "/ping"
    host                = "localhost"
  }
  service_port = 5601
  target_tags  = ["${var.region}-traefik-clients"]
  allowed_ips  = var.allowed_ips
}
