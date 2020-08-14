variable "region" {
  type        = string
  description = "Vault region name"
}

variable "config_bucket" {
  type        = string
  description = "Storage Bucket name for Config files"
}

variable "dnszone" {
  type        = string
  description = "DNS Zone Name for Vault certs"
}
