variable "project_id" {
  type    = string
  default = "methridge-sandbox"
}

variable "username" {
  type    = string
  default = "methridge"
}

variable "zone" {
  type    = string
  default = "us-central1-f"
}

variable "consul_ent" {
  type    = bool
  default = true
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

variable "nomad_version" {
  type    = string
  default = ""
}

variable "terraform_version" {
  type    = string
  default = ""
}

variable "vault_ent" {
  type    = bool
  default = true
}

variable "vault_version" {
  type    = string
  default = ""
}
