variable "username" {}
variable "project" {}
variable "region" {}
variable "region_output" {}
variable "admin_ip" {}
variable "machine_type" {}
variable "consul_ent" {}
variable "vault_ent" {}
variable "nomad_ent" {}
variable "elk_stack" {}
variable "consul_enable_non_voting" {}
variable "region_tls_priv_key" {}
variable "region_tls_cert_chain" {}
variable "regions" {
  type = set(string)
}
