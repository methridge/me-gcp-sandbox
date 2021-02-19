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

variable "image" {
  type        = string
  description = "Hashistack machine image name"
}

variable "network" {
  type        = string
  description = "VPC Network self_link"
}

variable "subnetwork" {
  type        = string
  description = "VPC subnetwork self_link"
}

variable "dnszone" {
  type        = string
  description = "DNS Zone name for LB"
}

variable "consul_token" {
  type        = string
  description = "Consul Master Token"
}

variable "consul_gossip_key" {
  type        = string
  description = "Consul Gossip Encryption Key"
}

variable "sandbox_ca_pem" {
  type        = string
  description = "Sandbox TLS CA"
}

variable "sandbox_ca_key" {
  type        = string
  description = "Sandbox TLS CA Key"
}

#
# Optional with defaults
#

variable "machine_type" {
  type        = string
  description = "Instance machine type"
  default     = "n1-standard-1"
}

variable "bastion_machine_type" {
  type        = string
  description = "Instance machine type for the Bastion host - May be larger when running ELK and Grafana"
  default     = "n1-standard-1"
}

variable "worker_machine_type" {
  type        = string
  description = "Instance machine type for the Bastion host - May be larger when running ELK and Grafana"
  default     = "n1-standard-1"
}

variable "allowed_ips" {
  type        = list(string)
  description = "The IP address ranges which can access the load balancer."
  default     = ["0.0.0.0/0"]
}

variable "consul_cluster_size" {
  type        = number
  description = "Number of nodes to deploy for the Consul cluster"
  default     = 3
}

variable "consul_enable_non_voting" {
  type        = bool
  description = "Enable Non-voting servers in cluster"
  default     = false
}

variable "consul_mode" {
  type        = string
  description = "Consul mode - client/server - Defaults to client"
  default     = "client"
}

variable "consul_primary_dc" {
  type        = string
  description = "Primary Consul Datacenter"
  default     = ""
}

variable "consul_wan_tag" {
  type        = string
  description = "Cluster tag to WAN join with this cluster"
  default     = ""
}

variable "custom_tags" {
  type        = list(string)
  description = "A list of tags that will be added to the Compute Instance Template in addition to the tags automatically added by this module."
  default     = []
}

variable "elk_stack" {
  type        = bool
  description = "Install the ELK and Grafana logging and monitoring on the Bastion"
  default     = false
}

variable "nomad_acl_enabled" {
  type        = bool
  description = "Enable Nomad ACLs"
  default     = false
}

variable "nomad_client_cluster_size" {
  type        = number
  description = "Number of nodes to deploy for the Nomad client cluster"
  default     = 3
}

variable "nomad_cluster_tag_name" {
  type        = string
  description = "Network tag used to join Nomad regions"
  default     = ""
}

variable "nomad_mode" {
  type        = string
  description = "Nomad mode none/client/server - Default blank for none"
  default     = ""
}

variable "nomad_server_cluster_size" {
  type        = number
  description = "Number of nodes to deploy for the Nomad server cluster"
  default     = 3
}

variable "nomad_server_join_tag" {
  type        = string
  description = "Cluster tag to WAN join Nomad servers"
  default     = ""
}

variable "vault_cluster_size" {
  type        = number
  description = "Number of nodes to deploy for the Vault cluster"
  default     = 3
}

variable "vault_storage" {
  type        = string
  description = "Vault storage to use - raft/consul - Defaults to blank for raft"
  default     = ""
}
