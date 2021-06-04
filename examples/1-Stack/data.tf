data "google_compute_image" "my_image" {
  name    = "${var.username}-sandbox"
  project = var.project
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

data "terraform_remote_state" "vpc" {
  backend = "remote"
  config = {
    organization = "methridge"
    workspaces = {
      name = "me-gcp-sandbox-network"
    }
  }
}

data "terraform_remote_state" "dns" {
  backend = "remote"
  config = {
    organization = "methridge"
    workspaces = {
      name = "me-gcp-sandbox-dns"
    }
  }
}

data "terraform_remote_state" "ssl" {
  backend = "remote"
  config = {
    organization = "methridge"
    workspaces = {
      name = "me-gcp-sandbox-ssl"
    }
  }
}
