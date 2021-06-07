resource "random_uuid" "consul_token" {}

resource "random_id" "consul_gossip_encryption_key" {
  byte_length = 32
}

module "sandbox-ca" {
  source = "../../modules/sandbox-ca"
}

module "region-stack" {
  for_each = var.region-map
  # source             = "github.com/methridge/ea-gcp-sandbox//modules/region-hashistack?ref=add-gcp-example"
  source                = "../../modules/region-hashistack"
  project               = var.project
  region                = each.key
  image                 = data.google_compute_image.my_image.name
  machine_type          = var.machine_type
  network               = data.terraform_remote_state.vpc.outputs.sandbox-network
  subnetwork            = data.terraform_remote_state.vpc.outputs.sandbox-subnets[0][each.key].self_link
  allowed_ips           = var.admin_ip
  custom_tags           = ["${var.username}-sandbox"]
  dnszone               = data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name
  zone_link             = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  elk_stack             = var.elk_stack
  consul_token          = random_uuid.consul_token.result
  consul_gossip_key     = random_id.consul_gossip_encryption_key.b64_std
  sandbox_ca_pem        = module.sandbox-ca.sandbox_ca_pem
  sandbox_ca_key        = module.sandbox-ca.sandbox_ca_key_pem
  region_tls_priv_key   = data.terraform_remote_state.ssl.outputs.regional-tls-certs[0][each.key].private_key_pem
  region_tls_cert_chain = "${data.terraform_remote_state.ssl.outputs.regional-tls-certs[0][each.key].certificate_pem}\n${data.terraform_remote_state.ssl.outputs.regional-tls-certs[0][each.key].issuer_pem}"
  bastion_machine_type  = "n1-standard-8"
  worker_machine_type   = "n1-standard-8"
  vault_storage         = "consul"
  # consul_enable_non_voting = true
  # vault_cluster_size       = 3
}

module "files-out" {
  for_each              = var.region-map
  source                = "../../modules/files-out"
  region_output         = each.value["out-dir"]
  consul_token          = random_uuid.consul_token.result
  consul_server_pem     = module.region-stack[each.key].consul_server_pem
  consul_server_pem_key = module.region-stack[each.key].consul_server_key_pem
  consul_client_pem     = module.region-stack[each.key].consul_client_pem
  consul_client_pem_key = module.region-stack[each.key].consul_client_key_pem
  sandbox_ca            = module.sandbox-ca.sandbox_ca_pem
  sandbox_ca_key        = module.sandbox-ca.sandbox_ca_key_pem
  vault_server_pem      = module.region-stack[each.key].vault_server_pem
  vault_server_pem_key  = module.region-stack[each.key].vault_server_key_pem
}


resource "null_resource" "stack-init" {
  for_each = var.region-map
  provisioner "local-exec" {
    command     = "${path.cwd}/../../scripts/stack-init.sh"
    working_dir = each.value["out-dir"]
    environment = {
      LB_IP    = module.region-stack[each.key].region-lb-ip
      GLB_IP   = module.region-stack[each.key].region-lb-global-ip
      DNS_ZONE = "${each.key}.${data.terraform_remote_state.dns.outputs.sandbox-dnszone-dns-name}"
    }
  }
  depends_on = [module.region-stack]
}
