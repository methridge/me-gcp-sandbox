resource "random_uuid" "consul_token" {}

resource "local_file" "consul_token" {
  content  = random_uuid.consul_token.result
  filename = "${path.module}/.tmp/consul.txt"
}

resource "random_id" "consul_gossip_encryption_key" {
  byte_length = 32
}

module "sandbox-ca" {
  source = "../../GitHubs/ea-gcp-sandbox/modules/sandbox-ca"
}

resource "local_file" "sandbox_ca" {
  content  = module.sandbox-ca.sandbox_ca_pem
  filename = "${path.module}/.tmp/sandbox-ca.pem"
}

resource "local_file" "sandbox_ca_key" {
  content  = module.sandbox-ca.sandbox_ca_key_pem
  filename = "${path.module}/.tmp/sandbox-ca-key.pem"
}

# Region-1 Stack
module "region-1-stack" {
  # source              = "github.com/methridge/ea-gcp-sandbox//modules/region-hashistack?ref=add-gcp-example"
  source                = "../../GitHubs/ea-gcp-sandbox/modules/region-hashistack"
  project               = var.project
  region                = var.region-name-1
  image                 = data.google_compute_image.my_image.name
  machine_type          = var.machine_type
  network               = data.terraform_remote_state.vpc.outputs.sandbox-network
  subnetwork            = data.terraform_remote_state.vpc.outputs.sandbox-subnet-region-1
  allowed_ips           = var.admin_ip
  custom_tags           = ["${var.username}-sandbox"]
  consul_wan_tag        = "${var.region-name-2}-consul-servers"
  nomad_server_join_tag = "nomad-servers"
  dnszone               = data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name
  consul_token          = random_uuid.consul_token.result
  consul_gossip_key     = random_id.consul_gossip_encryption_key.b64_std
  consul_primary_dc     = var.region-name-1
  sandbox_ca_pem        = module.sandbox-ca.sandbox_ca_pem
  sandbox_ca_key        = module.sandbox-ca.sandbox_ca_key_pem
  bastion_machine_type  = "n1-standard-8"
  worker_machine_type   = "n1-standard-8"
  vault_storage         = "consul"
  # elk_stack             = var.elk_stack
  # vault_cluster_size    = 3
}

resource "google_dns_record_set" "bastion-region-1" {
  project      = var.project
  name         = "bastion.${var.region-name-1}.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
  type         = "A"
  ttl          = 60
  managed_zone = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  rrdatas      = [module.region-1-stack.region-bastion-ip]
}

resource "google_dns_record_set" "lb-region-1" {
  project      = var.project
  name         = "lb.${var.region-name-1}.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
  type         = "A"
  ttl          = 60
  managed_zone = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  rrdatas      = [module.region-1-stack.region-lb-ip]
}

resource "google_dns_record_set" "region-1-consul" {
  project      = var.project
  name         = "consul.${var.region-name-1}.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
  type         = "A"
  ttl          = 60
  managed_zone = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  rrdatas      = [module.region-1-stack.region-lb-global-ip]
}

resource "google_dns_record_set" "region-1-nomad" {
  project      = var.project
  name         = "nomad.${var.region-name-1}.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
  type         = "A"
  ttl          = 60
  managed_zone = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  rrdatas      = [module.region-1-stack.region-lb-global-ip]
}

resource "google_dns_record_set" "region-1-vault" {
  project      = var.project
  name         = "vault.${var.region-name-1}.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
  type         = "A"
  ttl          = 60
  managed_zone = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  rrdatas      = [module.region-1-stack.region-lb-global-ip]
}

resource "local_file" "region_1_consul_server_pem" {
  content  = module.region-1-stack.consul_server_pem
  filename = "${path.module}/r1/.tmp/consul-server.pem"
}

resource "local_file" "region_1_consul_server_pem_key" {
  content  = module.region-1-stack.consul_server_key_pem
  filename = "${path.module}/r1/.tmp/consul-server-key.pem"
}

resource "local_file" "region_1_consul_client_pem" {
  content  = module.region-1-stack.consul_client_pem
  filename = "${path.module}/r1/.tmp/consul-client.pem"
}

resource "local_file" "region_1_consul_client_pem_key" {
  content  = module.region-1-stack.consul_client_key_pem
  filename = "${path.module}/r1/.tmp/consul-client-key.pem"
}

resource "local_file" "region_1_vault_server_pem" {
  content  = module.region-1-stack.vault_server_pem
  filename = "${path.module}/r1/.tmp/vault.pem"
}

resource "local_file" "region_1_vault_server_pem_key" {
  content  = module.region-1-stack.vault_server_key_pem
  filename = "${path.module}/r1/.tmp/vault-key.pem"
}

resource "null_resource" "r1-stack-init" {
  provisioner "local-exec" {
    command     = "../../../GitHubs/ea-gcp-sandbox/scripts/stack-init.sh"
    working_dir = "${path.module}/r1/"
    environment = {
      LB_IP    = module.region-1-stack.region-lb-ip
      GLB_IP   = module.region-1-stack.region-lb-global-ip
      DNS_ZONE = "${var.region-name-1}.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
    }
  }
  provisioner "local-exec" {
    command     = "../../../GitHubs/ea-gcp-sandbox/scripts/stack-destroy.sh"
    working_dir = "${path.module}/r1/"
    when        = destroy
  }
  depends_on = [module.region-1-stack]
}

# Region-2 Stack
module "region-2-stack" {
  # source              = "github.com/methridge/ea-gcp-sandbox//modules/region-hashistack?ref=add-gcp-example"
  source                = "../../GitHubs/ea-gcp-sandbox/modules/region-hashistack"
  project               = var.project
  region                = var.region-name-2
  image                 = data.google_compute_image.my_image.name
  machine_type          = var.machine_type
  network               = data.terraform_remote_state.vpc.outputs.sandbox-network
  subnetwork            = data.terraform_remote_state.vpc.outputs.sandbox-subnet-region-2
  allowed_ips           = var.admin_ip
  custom_tags           = ["${var.username}-sandbox"]
  consul_wan_tag        = "${var.region-name-3}-consul-servers"
  nomad_server_join_tag = "nomad-servers"
  dnszone               = data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name
  consul_token          = random_uuid.consul_token.result
  consul_gossip_key     = random_id.consul_gossip_encryption_key.b64_std
  consul_primary_dc     = var.region-name-1
  sandbox_ca_pem        = module.sandbox-ca.sandbox_ca_pem
  sandbox_ca_key        = module.sandbox-ca.sandbox_ca_key_pem
  bastion_machine_type  = "n1-standard-8"
  worker_machine_type   = "n1-standard-8"
  vault_storage         = "consul"
  # vault_cluster_size    = 3
  # elk_stack             = var.elk_stack
}

resource "google_dns_record_set" "bastion-region-2" {
  project      = var.project
  name         = "bastion.${var.region-name-2}.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
  type         = "A"
  ttl          = 60
  managed_zone = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  rrdatas      = [module.region-2-stack.region-bastion-ip]
}

resource "google_dns_record_set" "lb-region-2" {
  project      = var.project
  name         = "lb.${var.region-name-2}.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
  type         = "A"
  ttl          = 60
  managed_zone = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  rrdatas      = [module.region-2-stack.region-lb-ip]
}

resource "google_dns_record_set" "region-2-consul" {
  project      = var.project
  name         = "consul.${var.region-name-2}.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
  type         = "A"
  ttl          = 60
  managed_zone = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  rrdatas      = [module.region-2-stack.region-lb-global-ip]
}

resource "google_dns_record_set" "region-2-nomad" {
  project      = var.project
  name         = "nomad.${var.region-name-2}.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
  type         = "A"
  ttl          = 60
  managed_zone = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  rrdatas      = [module.region-2-stack.region-lb-global-ip]
}

resource "google_dns_record_set" "region-2-vault" {
  project      = var.project
  name         = "vault.${var.region-name-2}.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
  type         = "A"
  ttl          = 60
  managed_zone = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  rrdatas      = [module.region-2-stack.region-lb-global-ip]
}

resource "local_file" "region_2_consul_server_pem" {
  content  = module.region-2-stack.consul_server_pem
  filename = "${path.module}/r2/.tmp/consul-server.pem"
}

resource "local_file" "region_2_consul_server_pem_key" {
  content  = module.region-2-stack.consul_server_key_pem
  filename = "${path.module}/r2/.tmp/consul-server-key.pem"
}

resource "local_file" "region_2_consul_client_pem" {
  content  = module.region-2-stack.consul_client_pem
  filename = "${path.module}/r2/.tmp/consul-client.pem"
}

resource "local_file" "region_2_consul_client_pem_key" {
  content  = module.region-2-stack.consul_client_key_pem
  filename = "${path.module}/r2/.tmp/consul-client-key.pem"
}

resource "local_file" "region_2_vault_server_pem" {
  content  = module.region-2-stack.vault_server_pem
  filename = "${path.module}/r2/.tmp/vault.pem"
}

resource "local_file" "region_2_vault_server_pem_key" {
  content  = module.region-2-stack.vault_server_key_pem
  filename = "${path.module}/r2/.tmp/vault-key.pem"
}

resource "null_resource" "r2-stack-init" {
  provisioner "local-exec" {
    command     = "../../../GitHubs/ea-gcp-sandbox/scripts/stack-init.sh"
    working_dir = "${path.module}/r2/"
    environment = {
      LB_IP    = module.region-2-stack.region-lb-ip
      GLB_IP   = module.region-2-stack.region-lb-global-ip
      DNS_ZONE = "${var.region-name-2}.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
    }
  }
  provisioner "local-exec" {
    command     = "../../../GitHubs/ea-gcp-sandbox/scripts/stack-destroy.sh"
    working_dir = "${path.module}/r2/"
    when        = destroy
  }
  depends_on = [module.region-2-stack]
}

# Region-3 Stack
module "region-3-stack" {
  # source                = "github.com/methridge/ea-gcp-sandbox//modules/region-hashistack?ref=add-gcp-example"
  source                = "../../GitHubs/ea-gcp-sandbox/modules/region-hashistack"
  project               = var.project
  region                = var.region-name-3
  image                 = data.google_compute_image.my_image.name
  machine_type          = var.machine_type
  network               = data.terraform_remote_state.vpc.outputs.sandbox-network
  subnetwork            = data.terraform_remote_state.vpc.outputs.sandbox-subnet-region-3
  allowed_ips           = var.admin_ip
  custom_tags           = ["${var.username}-sandbox"]
  consul_wan_tag        = "${var.region-name-1}-consul-servers"
  nomad_server_join_tag = "nomad-servers"
  dnszone               = data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name
  consul_token          = random_uuid.consul_token.result
  consul_gossip_key     = random_id.consul_gossip_encryption_key.b64_std
  consul_primary_dc     = var.region-name-1
  sandbox_ca_pem        = module.sandbox-ca.sandbox_ca_pem
  sandbox_ca_key        = module.sandbox-ca.sandbox_ca_key_pem
  bastion_machine_type  = "n1-standard-8"
  worker_machine_type   = "n1-standard-8"
  vault_storage         = "consul"
  # vault_cluster_size    = 3
  # elk_stack             = var.elk_stack
}

resource "google_dns_record_set" "bastion-region-3" {
  project      = var.project
  name         = "bastion.${var.region-name-3}.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
  type         = "A"
  ttl          = 60
  managed_zone = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  rrdatas      = [module.region-3-stack.region-bastion-ip]
}

resource "google_dns_record_set" "lb-region-3" {
  project      = var.project
  name         = "lb.${var.region-name-3}.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
  type         = "A"
  ttl          = 60
  managed_zone = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  rrdatas      = [module.region-3-stack.region-lb-ip]
}

resource "google_dns_record_set" "region-3-consul" {
  project      = var.project
  name         = "consul.${var.region-name-3}.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
  type         = "A"
  ttl          = 60
  managed_zone = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  rrdatas      = [module.region-3-stack.region-lb-global-ip]
}

resource "google_dns_record_set" "region-3-nomad" {
  project      = var.project
  name         = "nomad.${var.region-name-3}.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
  type         = "A"
  ttl          = 60
  managed_zone = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  rrdatas      = [module.region-3-stack.region-lb-global-ip]
}

resource "google_dns_record_set" "region-3-vault" {
  project      = var.project
  name         = "vault.${var.region-name-3}.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
  type         = "A"
  ttl          = 60
  managed_zone = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  rrdatas      = [module.region-3-stack.region-lb-global-ip]
}

resource "local_file" "region_3_consul_server_pem" {
  content  = module.region-3-stack.consul_server_pem
  filename = "${path.module}/r3/.tmp/consul-server.pem"
}

resource "local_file" "region_3_consul_server_pem_key" {
  content  = module.region-3-stack.consul_server_key_pem
  filename = "${path.module}/r3/.tmp/consul-server-key.pem"
}

resource "local_file" "region_3_consul_client_pem" {
  content  = module.region-3-stack.consul_client_pem
  filename = "${path.module}/r3/.tmp/consul-client.pem"
}

resource "local_file" "region_3_consul_client_pem_key" {
  content  = module.region-3-stack.consul_client_key_pem
  filename = "${path.module}/r3/.tmp/consul-client-key.pem"
}

resource "local_file" "region_3_vault_server_pem" {
  content  = module.region-3-stack.vault_server_pem
  filename = "${path.module}/r3/.tmp/vault.pem"
}

resource "local_file" "region_3_vault_server_pem_key" {
  content  = module.region-3-stack.vault_server_key_pem
  filename = "${path.module}/r3/.tmp/vault-key.pem"
}

resource "null_resource" "r3-stack-init" {
  provisioner "local-exec" {
    command     = "../../../GitHubs/ea-gcp-sandbox/scripts/stack-init.sh"
    working_dir = "${path.module}/r3/"
    environment = {
      LB_IP    = module.region-3-stack.region-lb-ip
      GLB_IP   = module.region-3-stack.region-lb-global-ip
      DNS_ZONE = "${var.region-name-3}.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
    }
  }
  provisioner "local-exec" {
    command     = "../../../GitHubs/ea-gcp-sandbox/scripts/stack-destroy.sh"
    working_dir = "${path.module}/r3/"
    when        = destroy
  }
  depends_on = [module.region-3-stack]
}
