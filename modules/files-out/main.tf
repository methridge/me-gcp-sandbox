resource "local_file" "consul_token" {
  content  = var.consul_token
  filename = "${var.region_output}/.tmp/consul.txt"
}

resource "local_file" "consul_server_pem" {
  content  = var.consul_server_pem
  filename = "${var.region_output}/.tmp/consul-server.pem"
}

resource "local_file" "consul_server_pem_key" {
  content  = var.consul_server_pem_key
  filename = "${var.region_output}/.tmp/consul-server-key.pem"
}

resource "local_file" "consul_client_pem" {
  content  = var.consul_client_pem
  filename = "${var.region_output}/.tmp/consul-client.pem"
}

resource "local_file" "consul_client_pem_key" {
  content  = var.consul_client_pem_key
  filename = "${var.region_output}/.tmp/consul-client-key.pem"
}

resource "local_file" "sandbox_ca" {
  content  = var.sandbox_ca
  filename = "${var.region_output}/.tmp/sandbox-ca.pem"
}

resource "local_file" "sandbox_ca_key" {
  content  = var.sandbox_ca_key
  filename = "${var.region_output}/.tmp/sandbox-ca-key.pem"
}

resource "local_file" "vault_server_pem" {
  content  = var.vault_server_pem
  filename = "${var.region_output}/.tmp/vault.pem"
}

resource "local_file" "vault_server_pem_key" {
  content  = var.vault_server_pem_key
  filename = "${var.region_output}/.tmp/vault-key.pem"
}
