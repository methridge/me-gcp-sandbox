variable "creds" {
  description = "Full path to your GCP credentials file"
}

variable "username" {
  description = "User name for access and to prefix all resources"
}

variable "project" {
  description = "GCP Project name"
}

variable "admin_ip" {
  description = "Your public IP for direct access"
}

data "google_compute_image" "my_image" {
  name    = "${var.username}-sandbox"
  project = var.project
}

variable "machine_type" {
  description = "Instance machine type"
}
