#!/bin/bash

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

  instance_ip_address=$(get_instance_ip_address)
  instance_name=$(get_instance_name)
  instance_region=$(get_instance_region)
  instance_zone=$(get_instance_zone)
  project_id=$(get_instance_project_id)
  cluster_size=$(get_instance_custom_metadata_value "$cluster_size_instance_metadata_key_name")

  cat > "/etc/consul.d/consul.hcl" <<EOF
advertise_addr = "$instance_ip_address"
bind_addr = "$instance_ip_address"
client_addr = "0.0.0.0"
datacenter = "$instance_region"
data_dir = "/opt/consul"
node_name = "$instance_name"
node_meta {
  zone = "$instance_zone"
}
retry_join = ["provider=gce project_name=$project_id tag_value=$cluster_tag_name"]
EOF

  if [[ "$server" == "true" ]]; then
    cat > "/etc/consul.d/server.hcl" <<EOF
server = true
bootstrap_expect = $cluster_size
ui = true
EOF

    if [[ "$cluster_wan_join_tag" != "" ]]; then
      cat > "/etc/consul.d/wan.hcl" <<EOF
retry_join_wan = ["provider=gce project_name=$project_id tag_value=$cluster_wan_join_tag"]
EOF
    fi
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
    esac

    shift
  done

  if [[ ("$server" == "true" && "$client" == "true") || ("$server" == "false" && "$client" == "false") ]]; then
    exit 1
  fi

  generate_consul_config \
    "$server" \
    "$cluster_tag_name" \
    "$CLUSTER_SIZE_INSTANCE_METADATA_KEY_NAME" \
    "$cluster_wan_join_tag"
    
  start_consul
}

run "$@"