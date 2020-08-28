variable "consul_ent" {
  type    = bool
  default = true
}

variable "consul_premium" {
  type    = bool
  default = false
}

variable "consul_template_version" {
  type    = string
  default = ""
}

variable "consul_version" {
  type    = string
  default = ""
}

variable "envconsul_version" {
  type    = string
  default = ""
}

variable "nomad_ent" {
  type    = bool
  default = true
}

variable "nomad_premium" {
  type    = bool
  default = false
}

variable "nomad_version" {
  type    = string
  default = ""
}

variable "premium_bucket" {
  type    = string
  default = "sandbox-bin"
}

variable "project_id" {
  type    = string
  default = "methridge-sandbox"
}

variable "terraform_version" {
  type    = string
  default = ""
}

variable "username" {
  type    = string
  default = "methridge"
}

variable "vault_ent" {
  type    = bool
  default = true
}

variable "vault_premium" {
  type    = bool
  default = false
}

variable "vault_version" {
  type    = string
  default = ""
}

variable "zone" {
  type    = string
  default = "us-central1-f"
}
