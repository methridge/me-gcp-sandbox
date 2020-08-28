#!/usr/bin/env bash

set -e

readonly GCP_COMPUTE_INSTANCE_METADATA_URL="http://metadata.google.internal/computeMetadata/v1"
readonly GCP_METADATA_REQUEST_HEADER="Metadata-Flavor: Google"

# Log the given message at the given level. All logs are written to stderr with a timestamp.
function log {
  local -r level="$1"
  local -r message="$2"
  local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  local -r script_name="$(basename "$0")"
  >&2 echo -e "${timestamp} [${level}] [$script_name] ${message}"
}

# Log the given message at INFO level. All logs are written to stderr with a timestamp.
function log_info {
  local -r message="$1"
  log "INFO" "$message"
}

# Log the given message at WARN level. All logs are written to stderr with a timestamp.
function log_warn {
  local -r message="$1"
  log "WARN" "$message"
}

# Log the given message at ERROR level. All logs are written to stderr with a timestamp.
function log_error {
  local -r message="$1"
  log "ERROR" "$message"
}

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
  local readonly vault_storage="$1"
  local readonly tls_cert_file="$2"
  local readonly tls_key_file="$3"
  local readonly auto_unseal_project="$4"
  local readonly auto_unseal_region="$5"
  local readonly auto_unseal_key_ring="$6"
  local readonly auto_unseal_crypto_key="$7"

  instance_ip_address=$(get_instance_ip_address)
  instance_region=$(get_instance_region)

  if [[ $vault_storage == "" ||
        $vault_storage == "raft" ]]; then
    log_info "Configuring Integrated Storage."

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

telemetry {
  dogstatsd_addr = "localhost:8125"
  disable_hostname = true
}

ui = true
EOF
  elif [[ $vault_storage == "consul" ]]; then
    log_info "Configuring Integrated Storage."

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

storage "consul" {
  address = "127.0.0.1:8500"
  path    = "vault"
}

ui = true
EOF
  else
    log_error "Unkown storage type"
    exit 1
  fi

  chown --recursive vault:vault /etc/vault.d
  chmod 640 /etc/vault.d/vault.hcl
}

function start_vault {
  systemctl daemon-reload
  systemctl start vault
}

function run {
  local vault_storage=""
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
      --vault-storage)
        vault_storage="$2"
        shift
        ;;
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

  if [[ ! -f /opt/vault/tls/ca.crt.pem && -f /tmp/files/vault-ca.pem ]]; then
    sudo mv /tmp/files/vault-ca.pem /opt/vault/tls/ca.crt.pem
    sudo mv /tmp/files/vault.pem /opt/vault/tls/vault.crt.pem
    sudo mv /tmp/files/vault-key.pem /opt/vault/tls/vault.key.pem
    sudo cp /opt/vault/tls/ca.crt.pem /usr/local/share/ca-certificates/custom.crt
    sudo update-ca-certificates
  fi

  generate_vault_config "$vault_storage" "$tls_cert_file" \
    "$tls_key_file" "$auto_unseal_project" \
    "$auto_unseal_region" "$auto_unseal_key_ring" \
    "$auto_unseal_crypto_key"

  start_vault
}

run "$@"