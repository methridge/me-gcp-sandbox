source "googlecompute" "sandbox-image" {
  image_family        = "${var.username}-sandbox"
  image_name          = "${var.username}-sandbox"
  project_id          = var.project_id
  source_image_family = "ubuntu-2004-lts"
  ssh_username        = "ubuntu"
  zone                = var.zone
}

build {
  sources = ["source.googlecompute.sandbox-image"]

  provisioner "shell" {
    inline = ["mkdir /tmp/files"]
  }
  provisioner "file" {
    destination = "/tmp/files"
    source      = "./files/"
  }
  provisioner "shell" {
    inline = ["mkdir /tmp/licenses"]
  }
  provisioner "file" {
    destination = "/tmp/licenses/consul.hclic"
    source      = var.consul_lic_file
  }
  provisioner "file" {
    destination = "/tmp/licenses/nomad.hclic"
    source      = var.nomad_lic_file
  }
  provisioner "file" {
    destination = "/tmp/licenses/vault.hclic"
    source      = var.vault_lic_file
  }
  provisioner "shell" {
    environment_vars = [
      "CONSUL_ENT=${var.consul_ent}",
      "CONSUL_VERSION=${var.consul_version}",
      "NOMAD_ENT=${var.nomad_ent}",
      "NOMAD_VERSION=${var.nomad_version}",
      "VAULT_ENT=${var.vault_ent}",
      "VAULT_VERSION=${var.vault_version}",
      "CONSUL_TEMPLATE_VERSION=${var.consul_template_version}",
      "ENVCONSUL_VERSION=${var.envconsul_version}",
      "TERRAFORM_VERSION=${var.terraform_version}"
    ]
    max_retries = "5"
    script      = "scripts/install-hashistack.sh"
  }
}
