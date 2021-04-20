output "sandbox_ca_key_pem" {
  value     = tls_private_key.sandbox-ca-key.private_key_pem
  sensitive = true
}
output "sandbox_ca_pem" {
  value     = tls_self_signed_cert.sandbox-ca.cert_pem
  sensitive = true
}

