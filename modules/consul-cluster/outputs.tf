output "gcp_region" {
  value = var.gcp_region
}

output "cluster_name" {
  value = var.cluster_name
}

output "cluster_tag_name" {
  value = var.cluster_tag_name
}

output "instance_group_url" {
  value = google_compute_region_instance_group_manager.consul_server.self_link
}

output "instance_group_name" {
  value = google_compute_region_instance_group_manager.consul_server.name
}

output "instance_group_full_url" {
  value = google_compute_region_instance_group_manager.consul_server.instance_group
}

output "instance_group_instance_group" {
  value = google_compute_region_instance_group_manager.consul_server.instance_group
}

output "firewall_rule_intracluster_url" {
  value = google_compute_firewall.allow_intracluster_consul.self_link
}

output "firewall_rule_intracluster_name" {
  value = google_compute_firewall.allow_intracluster_consul.name
}

output "firewall_rule_inbound_http_url" {
  value = element(
    concat(
      google_compute_firewall.allow_inbound_http_api.*.self_link,
      [""],
    ),
    0,
  )
}

output "firewall_rule_inbound_http_name" {
  value = element(
    concat(google_compute_firewall.allow_inbound_http_api.*.name, [""]),
    0,
  )
}

output "firewall_rule_inbound_dns_url" {
  value = element(
    concat(google_compute_firewall.allow_inbound_dns.*.self_link, [""]),
    0,
  )
}

output "firewall_rule_inbound_dns_name" {
  value = element(
    concat(google_compute_firewall.allow_inbound_dns.*.name, [""]),
    0,
  )
}

output "cluster_health_check" {
  value = google_compute_health_check.consul_hc.self_link
}
