# ---------------------------------------------------------------------------------------------------------------------
# CREATE A REGIONAL MANAGED INSTANCE GROUP TO RUN CONSUL SERVER
# ---------------------------------------------------------------------------------------------------------------------

# Create Consul Health Check
resource "google_compute_health_check" "consul_hc" {
  project             = var.gcp_project_id
  name                = "${var.gcp_region}-${var.cluster_name}-hc"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10

  tcp_health_check {
    port = var.http_api_port
  }

  log_config {
    enable = true
  }
}

# Create the Regional Managed Instance Group where Consul Server will live.
resource "google_compute_region_instance_group_manager" "consul_server" {
  project            = var.gcp_project_id
  region             = var.gcp_region
  name               = "${var.cluster_name}-ig"
  target_pools       = var.instance_group_target_pools
  target_size        = var.enable_non_voting ? (var.cluster_size * 2) : var.cluster_size
  base_instance_name = var.cluster_name

  version {
    instance_template = google_compute_instance_template.consul_server_private.self_link
  }

  named_port {
    name = "consul"
    port = var.http_api_port
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.consul_hc.self_link
    initial_delay_sec = var.health_check_delay
  }

  update_policy {
    type                         = "PROACTIVE"
    instance_redistribution_type = "PROACTIVE"
    minimal_action               = "REPLACE"
    max_surge_fixed              = var.enable_non_voting ? (var.cluster_size * 2) : var.cluster_size
    max_unavailable_fixed        = 0
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [google_compute_instance_template.consul_server_private]
}

# Create the Instance Template that will be used to populate the Managed Instance Group.
resource "google_compute_instance_template" "consul_server_private" {
  project                 = var.gcp_project_id
  name_prefix             = "${var.cluster_name}-"
  description             = var.cluster_description
  instance_description    = var.cluster_description
  machine_type            = var.machine_type
  tags                    = concat([var.cluster_tag_name], var.custom_tags)
  metadata_startup_script = var.startup_script
  metadata = merge(
    {
      (var.metadata_key_name_for_cluster_size) = (var.cluster_size)
    },
    var.custom_metadata,
  )

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
  }

  disk {
    boot         = true
    auto_delete  = true
    source_image = var.source_image
    disk_size_gb = var.root_volume_disk_size_gb
    disk_type    = var.root_volume_disk_type
  }

  network_interface {
    network            = var.subnetwork_name != null ? null : var.network_name
    subnetwork         = var.subnetwork_name != null ? var.subnetwork_name : null
    subnetwork_project = var.network_project_id != null ? var.network_project_id : var.gcp_project_id
  }

  service_account {
    email = var.service_account_email
    scopes = concat(
      [
        "cloud-platform",
        "userinfo-email",
        "compute-rw",
        var.storage_access_scope
      ],
      var.service_account_scopes,
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE FIREWALL RULES
# ---------------------------------------------------------------------------------------------------------------------

# Allow Consul-specific traffic within the cluster
# - This Firewall Rule may be redundant depending on the settings of your VPC Network, but if your Network is locked down,
#   this Rule will open up the appropriate ports.
resource "google_compute_firewall" "allow_intracluster_consul" {
  project = var.network_project_id != null ? var.network_project_id : var.gcp_project_id

  name    = "${var.cluster_name}-rule-cluster"
  network = var.network_name

  allow {
    protocol = "tcp"

    ports = [
      var.server_rpc_port,
      var.cli_rpc_port,
      var.serf_lan_port,
      var.serf_wan_port,
      var.http_api_port,
      var.dns_port,
    ]
  }

  allow {
    protocol = "udp"

    ports = [
      var.serf_lan_port,
      var.serf_wan_port,
      var.dns_port,
    ]
  }

  source_tags = [var.cluster_tag_name]
  target_tags = [var.cluster_tag_name]
}

# Specify which traffic is allowed into the Consul Cluster solely for HTTP API requests
# - This Firewall Rule may be redundant depending on the settings of your VPC Network, but if your Network is locked down,
#   this Rule will open up the appropriate ports.
# - This Firewall Rule is only created if at least one source tag or source CIDR block is specified.
resource "google_compute_firewall" "allow_inbound_http_api" {
  count = length(var.allowed_inbound_cidr_blocks_dns) + length(var.allowed_inbound_tags_dns) > 0 ? 1 : 0

  project = var.network_project_id != null ? var.network_project_id : var.gcp_project_id

  name    = "${var.cluster_name}-rule-external-api-access"
  network = var.network_name

  allow {
    protocol = "tcp"

    ports = [
      var.http_api_port,
    ]
  }

  source_ranges = var.allowed_inbound_cidr_blocks_http_api
  source_tags   = var.allowed_inbound_tags_http_api
  target_tags   = [var.cluster_tag_name]
}

# Specify which traffic is allowed into the Consul Cluster solely for DNS requests
# - This Firewall Rule may be redundant depending on the settings of your VPC Network, but if your Network is locked down,
#   this Rule will open up the appropriate ports.
# - This Firewall Rule is only created if at least one source tag or source CIDR block is specified.
resource "google_compute_firewall" "allow_inbound_dns" {
  count = length(var.allowed_inbound_cidr_blocks_dns) + length(var.allowed_inbound_tags_dns) > 0 ? 1 : 0

  project = var.network_project_id != null ? var.network_project_id : var.gcp_project_id

  name    = "${var.cluster_name}-rule-external-dns-access"
  network = var.network_name

  allow {
    protocol = "tcp"

    ports = [
      var.dns_port,
    ]
  }

  allow {
    protocol = "udp"

    ports = [
      var.dns_port,
    ]
  }

  source_ranges = var.allowed_inbound_cidr_blocks_dns
  source_tags   = var.allowed_inbound_tags_dns
  target_tags   = [var.cluster_tag_name]
}

resource "google_compute_firewall" "allow_consul_health_checks" {
  name    = "${var.cluster_name}-rule-healthcheck-access"
  network = var.network_name
  project = var.network_project_id != null ? var.network_project_id : var.gcp_project_id

  allow {
    protocol = "tcp"
    ports = [
      var.http_api_port,
    ]
  }
  source_ranges = var.gcp_health_check_cidr
}
