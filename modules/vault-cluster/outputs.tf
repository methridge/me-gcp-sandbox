output "cluster_tag_name" {
  value = var.cluster_name
}

output "cluster_service_account" {
  value = local.service_account_email
}

output "instance_group_id" {
  value = google_compute_region_instance_group_manager.vault.id
}

output "instance_group_name" {
  value = google_compute_region_instance_group_manager.vault.name
}

output "instance_group_instance_group" {
  value = google_compute_region_instance_group_manager.vault.instance_group
}

output "instance_group_url" {
  value = google_compute_region_instance_group_manager.vault.self_link
}

output "instance_template_url" {
  value = data.template_file.compute_instance_template_self_link.rendered
}

output "firewall_rule_allow_intracluster_vault_url" {
  value = google_compute_firewall.allow_intracluster_vault.self_link
}

output "firewall_rule_allow_intracluster_vault_id" {
  value = google_compute_firewall.allow_intracluster_vault.id
}

output "firewall_rule_allow_inbound_api_url" {
  value = google_compute_firewall.allow_inbound_api.*.self_link
}

output "firewall_rule_allow_inbound_api_id" {
  value = google_compute_firewall.allow_inbound_api.*.id
}

output "cluster_health_check" {
  value = google_compute_health_check.vault_hc.self_link
}
