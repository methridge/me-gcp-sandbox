# Create Sandbox TLS CA Key
resource "tls_private_key" "sandbox-ca-key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

# resource "google_storage_bucket_object" "sandbox-ca-key-file" {
#   name    = "sandbox-ca-key.pem"
#   bucket  = var.config_bucket
#   content = tls_private_key.sandbox-ca-key.private_key_pem
# }

# Create Vault TLS CA Certificate
resource "tls_self_signed_cert" "sandbox-ca" {
  key_algorithm         = "ECDSA"
  private_key_pem       = tls_private_key.sandbox-ca-key.private_key_pem
  validity_period_hours = "43800"
  is_ca_certificate     = true
  set_subject_key_id    = true

  subject {
    common_name         = "Sandbox CA"
    organization        = "HashiCorp Inc."
    organizational_unit = ""
    street_address      = ["101 Second Street"]
    locality            = "San Francisco"
    province            = "CA"
    country             = "US"
    postal_code         = "94105"
  }


  allowed_uses = [
    "digital_signature",
    "cert_signing",
    "crl_signing"
  ]
}

# resource "google_storage_bucket_object" "sandbox-ca-file" {
#   name    = "sandbox-ca.pem"
#   bucket  = var.config_bucket
#   content = tls_self_signed_cert.sandbox-ca.cert_pem
# }
