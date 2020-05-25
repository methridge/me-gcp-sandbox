variable "creds" {
  description = "Full path to your GCP credentials file"
}

variable "username" {
  description = "User name for access and to prefix all resources"
}

variable "project" {
  description = "GCP Project name"
}

variable "zone_name" {
  description = "Your public DNS Zone (Must end with a dot)"
}
