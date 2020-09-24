variable "dc" {
  type        = string
  description = "Consul DC Name"
}

variable "config_bucket" {
  type        = string
  description = "Storage Bucket name for Config files"
}

variable "dnszone" {
  type        = string
  description = "DNS Zone Name for Vault certs"
}

variable "sandbox_ca_pem" {
  type        = string
  description = "Sandbox TLS CA"
}

variable "sandbox_ca_key" {
  type        = string
  description = "Sandbox TLS CA Key"
}
