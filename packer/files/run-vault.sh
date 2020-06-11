#!/bin/bash

set -e

readonly GCP_COMPUTE_INSTANCE_METADATA_URL="http://metadata.google.internal/computeMetadata/v1"
readonly GCP_METADATA_REQUEST_HEADER="Metadata-Flavor: Google"

# Get the value at a specific Instance Metadata path.
function get_instance_metadata_value {
  local readonly path="$1"
  curl --silent --show-error --location --header "$GCP_METADATA_REQUEST_HEADER" "$GCP_COMPUTE_INSTANCE_METADATA_URL/$path"
}

# Get the GCE Region in which this Compute Instance currently resides
function get_instance_region {
  get_instance_metadata_value "instance/zone" | cut -d'/' -f4 | awk -F'-' '{ print $1"-"$2 }'
}

# Get the IP Address of the current Compute Instance
function get_instance_ip_address {
  local network_interface_number="$1"

  # If no network interface number was specified, default to the first one
  if [[ -z "$network_interface_number" ]]; then
    network_interface_number=0
  fi

  get_instance_metadata_value "instance/network-interfaces/$network_interface_number/ip"
}

function generate_vault_config {
  local readonly tls_cert_file="$1"
  local readonly tls_key_file="$2"
  local readonly auto_unseal_project="${3}"
  local readonly auto_unseal_region="${4}"
  local readonly auto_unseal_key_ring="${5}"
  local readonly auto_unseal_crypto_key="${6}"

  instance_ip_address=$(get_instance_ip_address)
  instance_region=$(get_instance_region)

  cat > "/etc/vault.d/vault.hcl" <<EOF
listener "tcp" {
  address         = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_cert_file   = "$tls_cert_file"
  tls_key_file    = "$tls_key_file"
}

cluster_addr  = "https://$instance_ip_address:8201"
api_addr      = "https://active.vault.service.$instance_region.consul:8200"

seal "gcpckms" {
  project     = "$auto_unseal_project"
  region      = "$auto_unseal_region"
  key_ring    = "$auto_unseal_key_ring"
  crypto_key  = "$auto_unseal_crypto_key"
}

storage "raft" {
  path = "/opt/vault/data"
  node_id = "vault-0"
}

service_registration "consul" {
  address      = "127.0.0.1:8500"
}

ui = true
EOF

  chown --recursive vault:vault /etc/vault.d
  chmod 640 /etc/vault.d/vault.hcl
}

function start_vault {
  systemctl daemon-reload
  systemctl start vault
}

function run {
  local tls_cert_file=""
  local tls_key_file=""
  local auto_unseal_project=""
  local auto_unseal_region=""
  local auto_unseal_key_ring=""
  local auto_unseal_crypto_key=""
  local all_args=()

  while [[ $# > 0 ]]; do
    local key="$1"

    case "$key" in
      --tls-cert-file)
        tls_cert_file="$2"
        shift
        ;;
      --tls-key-file)
        tls_key_file="$2"
        shift
        ;;
      --auto-unseal-key-project-id)
        auto_unseal_project="$2"
        shift
        ;;
      --auto-unseal-key-region)
        auto_unseal_region="$2"
        shift
        ;;
      --auto-unseal-key-ring)
        auto_unseal_key_ring="$2"
        shift
        ;;
      --auto-unseal-crypto-key-name)
        auto_unseal_crypto_key="$2"
        shift
        ;;
      *)
        exit 1
        ;;
    esac

    shift
  done

  generate_vault_config "$tls_cert_file" "$tls_key_file" \
    "$auto_unseal_project" "$auto_unseal_region" \
    "$auto_unseal_key_ring" "$auto_unseal_crypto_key"

  start_vault
}

run "$@"