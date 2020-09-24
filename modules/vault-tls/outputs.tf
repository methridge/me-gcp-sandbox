output "vault_server_key_pem" {
  value = tls_private_key.vault-server-key.private_key_pem
}

output "vault_server_pem" {
  value = tls_locally_signed_cert.vault-server-cert.cert_pem
}
