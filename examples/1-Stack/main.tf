resource "random_uuid" "consul_token" {}

resource "local_file" "consul_token" {
  content  = random_uuid.consul_token.result
  filename = "${path.module}/.tmp/consul.txt"
}

resource "random_id" "consul_gossip_encryption_key" {
  byte_length = 32
}

module "sandbox-ca" {
  source = "../../modules/sandbox-ca"
}

resource "local_file" "sandbox_ca" {
  content  = module.sandbox-ca.sandbox_ca_pem
  filename = "${path.module}/.tmp/sandbox-ca.pem"
}

resource "local_file" "sandbox_ca_key" {
  content  = module.sandbox-ca.sandbox_ca_key_pem
  filename = "${path.module}/.tmp/sandbox-ca-key.pem"
}

module "region-1-stack" {
  # source             = "github.com/hashicorp/ea-gcp-sandbox//modules/region-hashistack?ref=add-gcp-example"
  source               = "../../modules/region-hashistack"
  project              = var.project
  region               = var.region
  image                = data.google_compute_image.my_image.name
  machine_type         = var.machine_type
  network              = data.terraform_remote_state.vpc.outputs.sandbox-network
  subnetwork           = data.terraform_remote_state.vpc.outputs.sandbox-subnet-region-1
  allowed_ips          = var.admin_ip
  custom_tags          = ["${var.username}-sandbox"]
  dnszone              = data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name
  elk_stack            = var.elk_stack
  consul_token         = random_uuid.consul_token.result
  consul_gossip_key    = random_id.consul_gossip_encryption_key.b64_std
  sandbox_ca_pem       = module.sandbox-ca.sandbox_ca_pem
  sandbox_ca_key       = module.sandbox-ca.sandbox_ca_key_pem
  bastion_machine_type = "n1-standard-8"
  worker_machine_type  = "n1-standard-8"
  vault_storage        = "consul"
  # consul_enable_non_voting = true
  # vault_cluster_size       = 3
}

resource "google_dns_record_set" "region-1-bastion" {
  project      = var.project
  name         = "bastion.${var.region}.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
  type         = "A"
  ttl          = 60
  managed_zone = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  rrdatas      = [module.region-1-stack.region-bastion-ip]
}

resource "google_dns_record_set" "region-1-lb" {
  project      = var.project
  name         = "lb.${var.region}.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
  type         = "A"
  ttl          = 60
  managed_zone = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  rrdatas      = [module.region-1-stack.region-lb-ip]
}

resource "google_dns_record_set" "region-1-consul" {
  project      = var.project
  name         = "consul.${var.region}.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
  type         = "A"
  ttl          = 60
  managed_zone = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  rrdatas      = [module.region-1-stack.region-lb-global-ip]
}

resource "google_dns_record_set" "region-1-nomad" {
  project      = var.project
  name         = "nomad.${var.region}.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
  type         = "A"
  ttl          = 60
  managed_zone = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  rrdatas      = [module.region-1-stack.region-lb-global-ip]
}

resource "google_dns_record_set" "region-1-vault" {
  project      = var.project
  name         = "vault.${var.region}.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
  type         = "A"
  ttl          = 60
  managed_zone = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  rrdatas      = [module.region-1-stack.region-lb-global-ip]
}

resource "local_file" "consul_server_pem" {
  content  = module.region-1-stack.consul_server_pem
  filename = "${path.module}/.tmp/consul-server.pem"
}

resource "local_file" "consul_server_pem_key" {
  content  = module.region-1-stack.consul_server_key_pem
  filename = "${path.module}/.tmp/consul-server-key.pem"
}

resource "local_file" "consul_client_pem" {
  content  = module.region-1-stack.consul_client_pem
  filename = "${path.module}/.tmp/consul-client.pem"
}

resource "local_file" "consul_client_pem_key" {
  content  = module.region-1-stack.consul_client_key_pem
  filename = "${path.module}/.tmp/consul-client-key.pem"
}

resource "local_file" "vault_server_pem" {
  content  = module.region-1-stack.vault_server_pem
  filename = "${path.module}/.tmp/vault.pem"
}

resource "local_file" "vault_server_pem_key" {
  content  = module.region-1-stack.vault_server_key_pem
  filename = "${path.module}/.tmp/vault-key.pem"
}

resource "null_resource" "stack-init" {
  provisioner "local-exec" {
    command     = "../../scripts/stack-init.sh"
    working_dir = path.module
    environment = {
      LB_IP    = module.region-1-stack.region-lb-ip
      GLB_IP   = module.region-1-stack.region-lb-global-ip
      DNS_ZONE = "${var.region}.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
    }
  }
  provisioner "local-exec" {
    command     = "../../scripts/stack-destroy.sh"
    working_dir = path.module
    when        = destroy
  }
  depends_on = [module.region-1-stack]
}
