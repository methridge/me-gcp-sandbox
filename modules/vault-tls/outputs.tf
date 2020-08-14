output "vault_ca_key_pem" {
  value = tls_private_key.vault-ca-key.private_key_pem
}

output "vault_ca_pem" {
  value = tls_self_signed_cert.vault-ca.cert_pem
}

output "vault_server_key_pem" {
  value = tls_private_key.vault-server-key.private_key_pem
}

output "vault_server_pem" {
  value = tls_locally_signed_cert.vault-server-cert.cert_pem
}
