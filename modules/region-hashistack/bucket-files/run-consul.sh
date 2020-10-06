#!/usr/bin/env bash

set -e

readonly COMPUTE_INSTANCE_METADATA_URL="http://metadata.google.internal/computeMetadata/v1"
readonly GOOGLE_CLOUD_METADATA_REQUEST_HEADER="Metadata-Flavor: Google"
readonly CLUSTER_SIZE_INSTANCE_METADATA_KEY_NAME="cluster-size"

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

# Get the GCE Region in which this Compute Instance currently resides
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

function generate_consul_config {
  local -r server="$1"
  local -r cluster_tag_name="$2"
  local -r cluster_size_instance_metadata_key_name="$3"
  local -r cluster_wan_join_tag="$4"
  local -r consul_primary_dc="$5"

  instance_ip_address=$(get_instance_ip_address)
  instance_name=$(get_instance_name)
  instance_region=$(get_instance_region)
  instance_zone=$(get_instance_zone)
  project_id=$(get_instance_project_id)
  cluster_size=$(get_instance_custom_metadata_value "$cluster_size_instance_metadata_key_name")
  gossip_key=$(</tmp/files/consul-tls/consul-gossip.txt)
  main_token=$(</tmp/files/consul-tls/consul-main-token.txt)
  client_token=$(</tmp/files/consul-tls/consul-client-token.txt)
  server_token=$(</tmp/files/consul-tls/consul-server-token.txt)

  cat > "/etc/consul.d/consul.hcl" <<EOF
advertise_addr = "$instance_ip_address"
bind_addr = "$instance_ip_address"
client_addr = "0.0.0.0"
datacenter = "$instance_region"
data_dir = "/opt/consul/data"
encrypt = "${gossip_key}"
node_name = "$instance_name"
node_meta {
  zone = "$instance_zone"
}
retry_join = ["provider=gce project_name=$project_id tag_value=$cluster_tag_name"]
verify_incoming = true
verify_outgoing = true
verify_server_hostname = true
ca_file = "/opt/consul/tls/consul-agent-ca.pem"
audit {
  enabled = true
  sink "Audit Sync" {
    type   = "file"
    format = "json"
    path   = "/opt/consul/log/audit-log.json"
    delivery_guarantee = "best-effort"
    rotate_duration = "24h"
    rotate_max_files = 15
    rotate_bytes = 25165824
  }
}
telemetry {
  dogstatsd_addr = "localhost:8125"
  disable_hostname = true
}
ports {
  https = 8501
  grpc = 8502
}
EOF

  if [[ "${consul_primary_dc}" != "" ]]; then
    echo "Primary DC defined as : ${consul_primary_dc}"
    cat > "/etc/consul.d/acl.hcl" <<EOF
primary_datacenter = "${consul_primary_dc}"
EOF
    if [[ "${instance_region}" != "${consul_primary_dc}" ]]; then
      echo "Consul DC is not Primary DC"
      cat >> "/etc/consul.d/acl.hcl" <<EOF
acl {
  enabled = true
  default_policy = "deny"
  enable_token_persistence = true
  enable_token_replication = true
  tokens {
    main = "${main_token}"
    agent  = "${main_token}"
    replication = "${main_token}"
  }
}
EOF
    else
      echo "Consul DC is Primary DC"
      cat >> "/etc/consul.d/acl.hcl" <<EOF
acl {
  enabled = true
  default_policy = "allow"
  enable_token_persistence = true
  tokens {
    main = "${main_token}"
    agent  = "${main_token}"
    replication = "${main_token}"
  }
}
EOF
    fi
  else
    echo "No Primary DC defined"
    cat >> "/etc/consul.d/acl.hcl" <<EOF
acl {
  enabled = true
  default_policy = "deny"
  enable_token_persistence = true
  tokens {
    main = "${main_token}"
    agent  = "${main_token}"
    replication = "${main_token}"
  }
}
EOF
  fi

  if [[ "$server" == "true" ]]; then
    cat > "/etc/consul.d/server.hcl" <<EOF
server = true
bootstrap_expect = $cluster_size
server_name = "server.${instance_region}.consul"
ui = true

connect {
  enabled = true
}

cert_file = "/opt/consul/tls/${instance_region}-server-consul-0.pem"
key_file = "/opt/consul/tls/${instance_region}-server-consul-0-key.pem"
EOF

    if [[ "$cluster_wan_join_tag" != "" ]]; then
      cat > "/etc/consul.d/wan.hcl" <<EOF
retry_join_wan = ["provider=gce project_name=$project_id tag_value=$cluster_wan_join_tag"]
EOF
    fi
  else
    cat > "/etc/consul.d/client.hcl" <<EOF
cert_file = "/opt/consul/tls/${instance_region}-client-consul-0.pem"
key_file = "/opt/consul/tls/${instance_region}-client-consul-0-key.pem"
EOF
  fi

  chmod 640 /etc/consul.d/*.hcl
  chown --recursive consul:consul /etc/consul.d
}

function start_consul {
  systemctl daemon-reload
  systemctl start consul
}

function run {
  local server="false"
  local client="false"
  local cluster_tag_name=""
  local cluster_wan_join_tag=""
  local consul_primary_dc=""

  while [[ $# > 0 ]]; do
    local key="$1"

    case "$key" in
      --server)
        server="true"
        ;;
      --client)
        client="true"
        ;;
      --cluster-tag-name)
        cluster_tag_name="$2"
        shift
        ;;
      --cluster-wan-join-tag)
        cluster_wan_join_tag="$2"
        shift
        ;;
      --consul-primary-dc)
        consul_primary_dc="$2"
        shift
        ;;
    esac

    shift
  done

  if [[ ("$server" == "true" && "$client" == "true") || ("$server" == "false" && "$client" == "false") ]]; then
    exit 1
  fi

  if [[ ! -f /opt/consul/tls/consul-agent-ca.pem && -f /tmp/files/consul-tls/consul-agent-ca.pem ]]; then
    sudo mv /tmp/files/consul-tls/*.pem /opt/consul/tls/
  fi

  generate_consul_config \
    "$server" \
    "$cluster_tag_name" \
    "$CLUSTER_SIZE_INSTANCE_METADATA_KEY_NAME" \
    "$cluster_wan_join_tag" \
    "$consul_primary_dc"
    
  start_consul
}

run "$@"