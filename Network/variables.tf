variable "creds" {
  type        = string
  description = "Full path to your GCP credentials file"
}

variable "username" {
  type        = string
  description = "User name for access and to prefix all resources"
}

variable "project" {
  type        = string
  description = "GCP Project name"
}

variable "region-name-1" {
  type        = string
  description = "Name for first Region"
}

variable "region-name-2" {
  type        = string
  description = "Name for second region"
}

variable "region-name-3" {
  type        = string
  description = "Name for third region"
}

variable "subnet-region-1" {
  type        = string
  description = "GCP Subnet for West-1 Region"
}

variable "subnet-region-2" {
  type        = string
  description = "GCP Subnet for Central-1 Region"
}

variable "subnet-region-3" {
  type        = string
  description = "GCP Subnet for East-1 Region"
}

variable "admin_ip" {
  type        = list(string)
  description = "Your public IP for direct access"
}
