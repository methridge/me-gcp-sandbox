#
# Required Variables
#

variable "project" {
  type        = string
  description = "GCP Project name"
}

variable "region" {
  type        = string
  description = "GCP Region for Hashistack deployment"
}

variable "dnszone" {
  type        = string
  description = "DNS Zone name for LB"
}

variable "zone-name" {
  type        = string
  description = "GCP Zone name"
}

variable "bastion-ip" {
  type        = string
  description = "IP of Bastion Host"
}

variable "lb-ip" {
  type        = string
  description = "IP of regional LB"
}

variable "glb-ip" {
  type        = string
  description = "IP of glboal LB"
}
