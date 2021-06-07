variable "project_id" {
  type = string
}

variable "username" {
  type = string
}

variable "zone" {
  type = string
}

variable "consul_ent" {
  type    = bool
  default = false
}

variable "consul_lic_file" {
  type    = string
  default = ""
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
  default = false
}

variable "nomad_lic_file" {
  type    = string
  default = ""
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
  default = false
}

variable "vault_lic_file" {
  type    = string
  default = ""
}

variable "vault_version" {
  type    = string
  default = ""
}
