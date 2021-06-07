variable "username" {}
variable "project" {}
variable "admin_ip" {}
variable "machine_type" {}
variable "consul_ent" {}
variable "vault_ent" {}
variable "nomad_ent" {}
variable "elk_stack" {}
variable "consul_enable_non_voting" {}
variable "region-map" {
  description = "Object Map of Regions (key) with CIDR block IP range and output directory items."
  type = map(
    object({
      cidr    = string
      name    = string
      out-dir = string
    })
  )
}
