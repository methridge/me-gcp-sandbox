variable "namespace" {
  description = "The name to prefix to resources to keep them unique."
}

variable "hostname" {
  description = "The hostname of the domain you wish to use, this will be subdomained. `example.com`"
}

variable "subdomain" {
  description = "The subdomain you wish to use `mycompany-tfe`"
}

variable "certificate_path" {
  description = "The path on disk that has the PFX certificate."
  default     = "./keys/certificate.pfx"
}

variable "tfe_license_file" {}

variable "credentials" {
  type        = string
  description = "Path to GCP credentials .json file"
}

variable "project" {
  type        = string
  description = "Name of the project to deploy into"
}

variable "region" {
  type        = string
  description = "The region to install into."
  default     = "us-central1"
}

variable "labels" {
  type        = map(string)
  description = "Labels to apply to the resources bucket"
  default     = {}
}

variable "public_ip_allowlist" {
  description = "List of public IP addresses to allow into the network."
  type        = list
  default     = []
}

variable "admin_email" {
  description = "Email address for admin of domain name"
  type        = string
}

variable "healthcheck_ips" {
  type        = list(string)
  description = "List of gcp health check ips to allow through the firewall"
  default     = ["35.191.0.0/16", "209.85.152.0/22", "209.85.204.0/22", "130.211.0.0/22"]
}
