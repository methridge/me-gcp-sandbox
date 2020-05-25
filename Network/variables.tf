variable "creds" {
  description = "Full path to your GCP credentials file"
}

variable "username" {
  description = "User name for access and to prefix all resources"
}

variable "project" {
  description = "GCP Project name"
}

variable "subnet-west1" {
  description = "GCP Subnet for West-1 Region"
}

variable "subnet-central1" {
  description = "GCP Subnet for Central-1 Region"
}

variable "subnet-east1" {
  description = "GCP Subnet for East-1 Region"
}

variable "admin_ip" {
  description = "Your public IP for direct access"
}
