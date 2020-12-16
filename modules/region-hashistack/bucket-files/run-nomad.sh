#!/usr/bin/env bash

set -e

readonly COMPUTE_INSTANCE_METADATA_URL="http://metadata.google.internal/computeMetadata/v1"
readonly GOOGLE_CLOUD_METADATA_REQUEST_HEADER="Metadata-Flavor: Google"

# Get the value at a specific Instance Metadata path.
function get_instance_metadata_value {
  local -r path="$1"
  curl --silent --show-error --location --header "$GOOGLE_CLOUD_METADATA_REQUEST_HEADER" "$COMPUTE_INSTANCE_METADATA_URL/$path"
}

# Get the value of the given Custom Metadata Key
function get_instance_custom_metadata_value {
  local -r key="$1"
  get_instance_metadata_value "instance/attributes/$key"
}

# Get the ID of the Project in which this Compute Instance currently resides
function get_instance_project_id {
  get_instance_metadata_value "project/project-id"
}

# Get the GCE Zone in which this Compute Instance currently resides
function get_instance_zone {
  get_instance_metadata_value "instance/zone" | cut -d'/' -f4
}

function get_instance_region {
  get_instance_zone | head -c -3
}

# Get the ID of the current Compute Instance
function get_instance_name {
  get_instance_metadata_value "instance/name"
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

function generate_nomad_config {
  local readonly server="$1"
  local readonly client="$2"
  local readonly num_servers="$3"
  local readonly cluster_tag_name="$4"
  local readonly enable_acls="$5"

  instance_name=$(get_instance_name)
  instance_ip_address=$(get_instance_ip_address)
  instance_region=$(get_instance_region)
  instance_zone=$(get_instance_zone)
  project_id=$(get_instance_project_id)
  master_token=$(</tmp/files/consul-tls/consul-master-token.txt)

  if [[ "$server" == "true" ]]; then
    cat > "/etc/nomad.d/server.hcl" <<EOF
server {
  enabled = true
  bootstrap_expect = $num_servers
  redundancy_zone = "$instance_zone"
}
autopilot {
  enable_redundancy_zones = true
}
EOF
  fi

  if [[ "$client" == "true" ]]; then
    cat > "/etc/nomad.d/client.hcl" <<EOF
client {
  enabled = true
}
EOF
  fi

  if [[ "$enable_acls" == "true" ]]; then
    cat > "/etc/nomad.d/acl.hcl" <<EOF
acl {
  enabled = true
}
EOF
fi

  cat > "/etc/nomad.d/nomad.hcl" <<EOF
datacenter         = "$instance_zone"
data_dir           = "/opt/nomad"
name               = "$instance_name"
region             = "$instance_region"
bind_addr          = "0.0.0.0"
leave_on_interrupt = true
leave_on_terminate = true

advertise {
  http = "$instance_ip_address"
  rpc  = "$instance_ip_address"
  serf = "$instance_ip_address"
}

server_join {
  retry_join = ["provider=gce project_name=$project_id tag_value=$cluster_tag_name"]
}

consul {
  address = "127.0.0.1:8501"
  ssl = true
  token   = "$master_token"
  ca_file = "/opt/consul/tls/consul-agent-ca.pem"
  cert_file = "/opt/consul/tls/${instance_region}-server-consul-0.pem"
  key_file = "/opt/consul/tls/${instance_region}-server-consul-0-key.pem"
}
EOF

  chown root:root /etc/nomad.d/nomad.hcl

}

function start_nomad {
  systemctl daemon-reload
  systemctl start nomad
}

function run {
  local server="false"
  local client="false"
  local enable_acls="false"
  local num_servers=""
  local cluster_tag_name=""
  local all_args=()

  while [[ $# > 0 ]]; do
    local key="$1"

    case "$key" in
      --server)
        server="true"
        ;;
      --client)
        client="true"
        ;;
      --enable-acls)
        enable_acls="$2"
        shift
        ;;
      --num-servers)
        num_servers="$2"
        shift
        ;;
      --cluster-tag-name)
        cluster_tag_name="$2"
        shift
        ;;
      *)
        exit 1
        ;;
    esac

    shift
  done

  if [[ "$server" == "false" && "$client" == "false" ]]; then
    log_error "At least one of --server or --client must be set"
    exit 1
  fi

  generate_nomad_config "$server" "$client" "$num_servers" "$cluster_tag_name" "$enable_acls"
  start_nomad
}

run "$@"