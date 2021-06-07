output "cluster_name" {
  value = var.cluster_name
}

output "cluster_tag_name" {
  value = var.cluster_name
}

output "instance_group_id" {
  value = google_compute_region_instance_group_manager.nomad.id
}

output "instance_group_url" {
  value = google_compute_region_instance_group_manager.nomad.self_link
}

output "instance_group_name" {
  value = google_compute_region_instance_group_manager.nomad.name
}

output "instance_group_instance_group" {
  value = google_compute_region_instance_group_manager.nomad.instance_group
}

output "cluster_health_check" {
  value = google_compute_health_check.nomad_hc.self_link
}
