variable "project" {
  description = "GCP Project name"
}

variable "region" {
  description = "GCP Region for Hashistack deployment"
}

variable "image" {
  description = "Hashi-world machine image name"
}

variable "machine_type" {
  description = "Instance machine type"
}

variable "network" {
  description = "VPC Network self_link"
}

variable "subnetwork" {
  description = "VPC subnetwork self_link"
}

variable "consul_cluster_size" {
  description = "Number of nodes to deploy for the Consul cluster"
  default     = 3
}

variable "consul_wan_tag" {
  description = "Cluster tag to WAN join with this cluster"
  default     = ""
}

variable "nomad_server_cluster_size" {
  description = "Number of nodes to deploy for the Nomad server cluster"
  default     = 3
}

variable "nomad_server_join_tag" {
  description = "Cluster tag to WAN join Nomad servers"
  default     = ""
}

variable "nomad_client_cluster_size" {
  description = "Number of nodes to deploy for the Nomad client cluster"
  default     = 3
}

variable "vault_cluster_size" {
  description = "Number of nodes to deploy for the Vault cluster"
  default     = 3
}

variable "allowed_ips" {
  description = "The IP address ranges which can access the load balancer."
  default     = ["0.0.0.0/0"]
  type        = list(string)
}

variable "custom_tags" {
  description = "A list of tags that will be added to the Compute Instance Template in addition to the tags automatically added by this module."
  type        = list(string)
  default     = []
}

variable "nomad_acl_enabled" {
  description = "Enable Nomad ACLs"
  default     = false
}
