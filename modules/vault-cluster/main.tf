data "google_compute_zones" "available" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

resource "google_compute_health_check" "vault_hc" {
  project             = var.gcp_project_id
  name                = "${var.gcp_region}-${var.cluster_name}-hc"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10

  ssl_health_check {
    port = var.api_port
  }

  log_config {
    enable = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATES A SERVICE ACCOUNT TO OPERATE THE VAULT CLUSTER
# The default project service account will be used if create_service_account
# is set to false and no service_account_email is provided.
# ---------------------------------------------------------------------------------------------------------------------

resource "google_service_account" "vault_cluster_admin" {
  count        = var.create_service_account ? 1 : 0
  account_id   = "${var.cluster_name}-admin-sa"
  display_name = "Vault Server Admin"
  project      = var.gcp_project_id
}

# Create a service account key
resource "google_service_account_key" "vault" {
  count              = var.create_service_account ? 1 : 0
  service_account_id = google_service_account.vault_cluster_admin[0].name
}

# Add viewer role to service account on project
resource "google_project_iam_member" "vault_cluster_admin_sa_view_project" {
  count   = var.create_service_account ? 1 : 0
  project = var.gcp_project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${local.service_account_email}"
}

# Does the same in case we're using a service account that has been previously created
resource "google_project_iam_member" "other_sa_view_project" {
  count   = var.use_external_service_account ? 1 : 0
  project = var.gcp_project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${var.service_account_email}"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A GCE MANAGED INSTANCE GROUP TO RUN VAULT
# Ideally, we would run a "regional" Managed Instance Group that spans many Zones, but the Terraform GCP provider has
# not yet implemented https://github.com/terraform-providers/terraform-provider-google/issues/45, so we settle for a
# single-zone Managed Instance Group.
# ---------------------------------------------------------------------------------------------------------------------

# Create the single-zone Managed Instance Group where Vault will run.
resource "google_compute_region_instance_group_manager" "vault" {
  project            = var.gcp_project_id
  region             = var.gcp_region
  name               = "${var.cluster_name}-ig"
  base_instance_name = var.cluster_name

  version {
    instance_template = google_compute_instance_template.vault_private.self_link
    name              = "${var.cluster_name}-vault-${var.vault_cluster_version}"
  }

  named_port {
    name = "vault"
    port = var.api_port
  }

  update_policy {
    type                         = "PROACTIVE"
    instance_redistribution_type = "PROACTIVE"
    minimal_action               = "REPLACE"
    max_surge_fixed              = (var.cluster_size >= length(data.google_compute_zones.available.names)) ? var.cluster_size : length(data.google_compute_zones.available.names)
    max_unavailable_fixed        = 0
    # min_ready_sec                = var.health_check_delay
  }

  target_pools = var.instance_group_target_pools
  target_size  = var.cluster_size

  auto_healing_policies {
    health_check      = google_compute_health_check.vault_hc.self_link
    initial_delay_sec = var.health_check_delay
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [google_compute_instance_template.vault_private]
}

# Create the Instance Template that will be used to populate the Managed Instance Group.
resource "google_compute_instance_template" "vault_private" {
  name_prefix = "${var.cluster_name}-"
  description = var.cluster_description
  project     = var.gcp_project_id

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

  # For a full list of oAuth 2.0 Scopes, see https://developers.google.com/identity/protocols/googlescopes
  service_account {
    email = local.service_account_email
    scopes = concat(
      [
        "userinfo-email",
        "compute-rw",
        "storage-ro",
        "cloud-platform",
      ],
      var.service_account_scopes,
    )
  }

  # Per Terraform Docs (https://www.terraform.io/docs/providers/google/r/compute_instance_template.html#using-with-instance-group-manager),
  # we need to create a new instance template before we can destroy the old one. Note that any Terraform resource on
  # which this Terraform resource depends will also need this lifecycle statement.
  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE FIREWALL RULES
# ---------------------------------------------------------------------------------------------------------------------

# Allow Vault-specific traffic within the cluster
# - This Firewall Rule may be redundant depending on the settings of your VPC Network, but if your Network is locked down,
#   this Rule will open up the appropriate ports.
resource "google_compute_firewall" "allow_intracluster_vault" {
  name    = "${var.cluster_name}-rule-cluster"
  network = var.network_name
  project = var.network_project_id != null ? var.network_project_id : var.gcp_project_id

  allow {
    protocol = "tcp"

    ports = [
      var.cluster_port,
    ]
  }

  source_tags = [var.cluster_tag_name]
  target_tags = [var.cluster_tag_name]
}

# Specify which traffic is allowed into the Vault cluster solely for API requests
# - This Firewall Rule may be redundant depending on the settings of your VPC Network, but if your Network is locked down,
#   this Rule will open up the appropriate ports.
# - This Firewall Rule is only created if at least one source tag or source CIDR block is specified.
resource "google_compute_firewall" "allow_inbound_api" {
  count = length(var.allowed_inbound_cidr_blocks_api) + length(var.allowed_inbound_tags_api) > 0 ? 1 : 0

  name    = "${var.cluster_name}-rule-external-api-access"
  network = var.network_name
  project = var.network_project_id != null ? var.network_project_id : var.gcp_project_id

  allow {
    protocol = "tcp"

    ports = [
      var.api_port,
    ]
  }

  source_ranges = var.allowed_inbound_cidr_blocks_api
  source_tags   = var.allowed_inbound_tags_api
  target_tags   = [var.cluster_tag_name]
}

resource "google_compute_firewall" "allow_vault_health_checks" {
  name    = "${var.cluster_name}-rule-healthcheck-access"
  network = var.network_name
  project = var.network_project_id != null ? var.network_project_id : var.gcp_project_id

  allow {
    protocol = "tcp"
    ports = [
      var.api_port,
    ]
  }
  source_ranges = var.gcp_health_check_cidr
}

# ---------------------------------------------------------------------------------------------------------------------
# CONVENIENCE VARIABLES
# Because we've got some conditional logic in this template, some values will depend on our properties. This section
# wraps such values in a nicer construct.
# ---------------------------------------------------------------------------------------------------------------------

# This is a work around so we don't have yet another combination of google_compute_instance_template
# with counts that depend on yet another flag
locals {
  service_account_email = var.create_service_account ? element(
    concat(google_service_account.vault_cluster_admin.*.email, [""]),
    0,
  ) : var.service_account_email
}
