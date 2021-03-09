variable "project" {
  type        = string
  description = "GCP Project name"
}

variable "region" {
  type        = string
  description = "GCP Region for Hashistack deployment"
}

variable "ip_allow_list" {
  type        = list(any)
  description = "IP CIDRs to alow. Defaults to the entire world."
  default     = ["0.0.0.0/0"]
}

variable "admin_email" {
  type        = string
  description = "Email address for admin of domain name"
}

variable "dnszone" {
  type        = string
  description = "DNS Zone Name for Vault certs"
}

variable "consul_ig" {
  type        = string
  description = "Consul instance group"
}

variable "consul_hc" {
  type        = string
  description = "Consul Health Check Self Link"
}

variable "nomad_ig" {
  type        = string
  description = "Nomad instance group"
}

variable "nomad_hc" {
  type        = string
  description = "Nomad Health Check Self Link"
}

variable "vault_ig" {
  type        = string
  description = "Vault instance group"
}

variable "vault_hc" {
  type        = string
  description = "Vault Health Check Self Link"
}
