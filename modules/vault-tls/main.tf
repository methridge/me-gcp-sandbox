resource "google_storage_bucket_object" "vault-ca-key-file" {
  name    = "vault-ca-key.pem"
  bucket  = var.config_bucket
  content = var.sandbox_ca_key
}

resource "google_storage_bucket_object" "vault-ca-file" {
  name    = "vault-ca.pem"
  bucket  = var.config_bucket
  content = var.sandbox_ca_pem
}

# Create Vault Server TLS Key
resource "tls_private_key" "vault-server-key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "google_storage_bucket_object" "vault-server-key-file" {
  name    = "vault-key.pem"
  bucket  = var.config_bucket
  content = tls_private_key.vault-server-key.private_key_pem
}

# Create Vault Server TLS Cert
resource "tls_cert_request" "vault-server-csr" {
  key_algorithm   = "ECDSA"
  private_key_pem = tls_private_key.vault-server-key.private_key_pem
  dns_names = [
    "localhost",
    "vault.service.consul",
    "*.vault.service.consul",
    "vault.service.${var.region}.consul",
    "*.vault.service.${var.region}.consul",
    "*.${var.dnszone}",
    "*.${var.region}.${var.dnszone}",
    "lb.${var.region}.${var.dnszone}",
  ]
  ip_addresses = ["127.0.0.1"]

  subject {
    common_name = "lb.${var.region}.${var.dnszone}"
  }
}

resource "tls_locally_signed_cert" "vault-server-cert" {
  cert_request_pem      = tls_cert_request.vault-server-csr.cert_request_pem
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

resource "google_storage_bucket_object" "vault-server-file" {
  name    = "vault.pem"
  bucket  = var.config_bucket
  content = tls_locally_signed_cert.vault-server-cert.cert_pem
}
