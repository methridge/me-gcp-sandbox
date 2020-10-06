locals {
  dnszone = trimsuffix(var.dnszone, ".")
}

resource "google_storage_bucket_object" "consul-ca-key-file" {
  name    = "consul-tls/consul-agent-ca-key.pem"
  bucket  = var.config_bucket
  content = var.sandbox_ca_key
}

resource "google_storage_bucket_object" "consul-ca-file" {
  name    = "consul-tls/consul-agent-ca.pem"
  bucket  = var.config_bucket
  content = var.sandbox_ca_pem
}

# Create Consul Server TLS Key
resource "tls_private_key" "consul-server-key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "google_storage_bucket_object" "consul-server-key-file" {
  name    = "consul-tls/${var.dc}-server-consul-0-key.pem"
  bucket  = var.config_bucket
  content = tls_private_key.consul-server-key.private_key_pem
}

# Create Consul Server TLS Cert
resource "tls_cert_request" "consul-server-csr" {
  key_algorithm   = "ECDSA"
  private_key_pem = tls_private_key.consul-server-key.private_key_pem
  dns_names = [
    "localhost",
    "server.${var.dc}.consul",
    "*.${local.dnszone}",
    "*.${var.dc}.${local.dnszone}",
    "lb.${var.dc}.${local.dnszone}",
  ]
  ip_addresses = ["127.0.0.1"]

  subject {
    common_name = "server.${var.dc}.consul"
  }
}

resource "tls_locally_signed_cert" "consul-server-cert" {
  cert_request_pem      = tls_cert_request.consul-server-csr.cert_request_pem
  ca_key_algorithm      = "ECDSA"
  ca_private_key_pem    = var.sandbox_ca_key
  ca_cert_pem           = var.sandbox_ca_pem
  validity_period_hours = 8760
  set_subject_key_id    = true

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

resource "google_storage_bucket_object" "consul-server-file" {
  name    = "consul-tls/${var.dc}-server-consul-0.pem"
  bucket  = var.config_bucket
  content = tls_locally_signed_cert.consul-server-cert.cert_pem
}

# Create Consul Client TLS Key
resource "tls_private_key" "consul-client-key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "google_storage_bucket_object" "consul-client-key-file" {
  name    = "consul-tls/${var.dc}-client-consul-0-key.pem"
  bucket  = var.config_bucket
  content = tls_private_key.consul-client-key.private_key_pem
}

# Create Consul Client TLS Cert
resource "tls_cert_request" "consul-client-csr" {
  key_algorithm   = "ECDSA"
  private_key_pem = tls_private_key.consul-client-key.private_key_pem
  dns_names       = ["client.${var.dc}.consul", "localhost"]
  ip_addresses    = ["127.0.0.1"]

  subject {
    common_name = "client.${var.dc}.consul"
  }
}

resource "tls_locally_signed_cert" "consul-client-cert" {
  cert_request_pem      = tls_cert_request.consul-client-csr.cert_request_pem
  ca_key_algorithm      = "ECDSA"
  ca_private_key_pem    = var.sandbox_ca_key
  ca_cert_pem           = var.sandbox_ca_pem
  validity_period_hours = 8760
  set_subject_key_id    = true

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

resource "google_storage_bucket_object" "consul-client-file" {
  name    = "consul-tls/${var.dc}-client-consul-0.pem"
  bucket  = var.config_bucket
  content = tls_locally_signed_cert.consul-client-cert.cert_pem
}

# Consul Security
# resource "random_uuid" "consul_main_token" {}

# resource "google_storage_bucket_object" "consul-main-token" {
#   name    = "consul-tls/consul-main-token.txt"
#   bucket  = var.config_bucket
#   content = random_uuid.consul_main_token.result
# }

resource "random_uuid" "consul_agent_client_token" {}

resource "google_storage_bucket_object" "consul-client-token" {
  name    = "consul-tls/consul-client-token.txt"
  bucket  = var.config_bucket
  content = random_uuid.consul_agent_client_token.result
}

resource "random_uuid" "consul_agent_server_token" {}

resource "google_storage_bucket_object" "consul-server-token" {
  name    = "consul-tls/consul-server-token.txt"
  bucket  = var.config_bucket
  content = random_uuid.consul_agent_server_token.result
}

resource "random_uuid" "consul_vault_app_token" {}

resource "google_storage_bucket_object" "consul-vault-app-token" {
  name    = "consul-tls/consul-vault-app-token.txt"
  bucket  = var.config_bucket
  content = random_uuid.consul_vault_app_token.result
}

# resource "random_id" "consul_gossip_encryption_key" {
#   byte_length = 32
# }

# resource "google_storage_bucket_object" "consul-gossip" {
#   name    = "consul-tls/consul-gossip.txt"
#   bucket  = var.config_bucket
#   content = random_id.consul_gossip_encryption_key.b64_std
# }
