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

variable "consul_ent" {
  type        = bool
  description = "Install Consul Enterprise binary - true/false - Defaults to false"
  default     = false
}

variable "consul_mode" {
  type        = string
  description = "Consul mode - client/server - Defaults to client"
  default     = "client"
}

variable "consul_prem" {
  type        = bool
  description = "Install Consul Premium binary - true/false - Defaults to false"
  default     = false
}

variable "consul_template_ver" {
  type        = string
  description = "Consul Template version to install - Default to latest"
  default     = ""
}

variable "consul_version" {
  type        = string
  description = "Consul Version - Default to latest"
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

variable "envconsul_ver" {
  type        = string
  description = "EnvConsul version to install - Default to latest"
  default     = ""
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

variable "nomad_ent" {
  type        = bool
  description = "Install Nomad Enterprise - bool"
  default     = false
}

variable "nomad_mode" {
  type        = string
  description = "Nomad mode none/client/server - Default blank for none"
  default     = ""
}

variable "nomad_prem" {
  type        = bool
  description = "Install Nomad premium - bool"
  default     = false
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

variable "nomad_version" {
  type        = string
  description = "Nomad version to install - Default to latest"
  default     = ""
}

variable "prem_bucket" {
  type        = string
  description = "Name of bucket with Premium binaries"
  default     = ""
}

variable "terraform_ver" {
  type        = string
  description = "Terraform version to install - Default to latest"
  default     = ""
}

variable "vault_cluster_size" {
  type        = number
  description = "Number of nodes to deploy for the Vault cluster"
  default     = 3
}

variable "vault_ent" {
  type        = bool
  description = "Install Vault Enterprise binary - true/false - Defaults to false"
  default     = false
}

variable "vault_mode" {
  type        = string
  description = "Vault mode - server/agent - Default to blank or none to not start vault"
  default     = ""
}

variable "vault_prem" {
  type        = bool
  description = "Install Vault premium binary - true/false - Defaults to false"
  default     = false
}

variable "vault_storage" {
  type        = string
  description = "Vault storage to use - raft/consul - Defaults to blank for raft"
  default     = ""
}

variable "vault_version" {
  type        = string
  description = "Vault version to install - Defaults to blank for latest"
  default     = ""
}
