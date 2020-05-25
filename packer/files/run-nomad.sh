#!/bin/bash
# This script is used to configure and run Nomad on a Google Compute Instance.

set -e

readonly NOMAD_CONFIG_FILE="default.hcl"
readonly SUPERVISOR_CONFIG_PATH="/etc/supervisor/conf.d/run-nomad.conf"

readonly COMPUTE_INSTANCE_METADATA_URL="http://metadata.google.internal/computeMetadata/v1"
readonly GOOGLE_CLOUD_METADATA_REQUEST_HEADER="Metadata-Flavor: Google"

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"

function print_usage {
  echo
  echo "Usage: run-nomad [OPTIONS]"
  echo
  echo "This script is used to configure and run Nomad on a Google Compute Instance."
  echo
  echo "Options:"
  echo
  echo -e "  --server\t\tIf set, run in server mode. Optional. At least one of --server or --client must be set."
  echo -e "  --client\t\tIf set, run in client mode. Optional. At least one of --server or --client must be set."
  echo -e "  --enable-acls\t\tIf set, enable ACLs. Optional."
  echo -e "  --num-servers\t\tThe minimum number of servers to expect in the Nomad cluster. Required if --server is true."
  echo -e "  --config-dir\t\tThe path to the Nomad config folder. Optional. Default is the absolute path of '../config', relative to this script."
  echo -e "  --data-dir\t\tThe path to the Nomad data folder. Optional. Default is the absolute path of '../data', relative to this script."
  echo -e "  --bin-dir\t\tThe path to the folder with Nomad binary. Optional. Default is the absolute path of the parent folder of this script."
  echo -e "  --log-dir\t\tThe path to the Nomad log folder. Optional. Default is the absolute path of '../log', relative to this script."
  echo -e "  --user\t\tThe user to run Nomad as. Optional. Default is to use the owner of --config-dir."
  echo -e "  --use-sudo\t\tIf set, run the Nomad agent with sudo. By default, sudo is only used if --client is set."
  echo -e "  --skip-nomad-config\tIf this flag is set, don't generate a Nomad configuration file. Optional. Default is false."
  echo -e "  --cluster-tag-name\tIf this flag is set, add server_join section to auto join based on this tag."
  echo
  echo "Example:"
  echo
  echo "  run-nomad --server --config-dir /custom/path/to/nomad/config"
}

function log {
  local readonly level="$1"
  local readonly message="$2"
  local readonly timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  >&2 echo -e "${timestamp} [${level}] [$SCRIPT_NAME] ${message}"
}

function log_info {
  local readonly message="$1"
  log "INFO" "$message"
}

function log_warn {
  local readonly message="$1"
  log "WARN" "$message"
}

function log_error {
  local readonly message="$1"
  log "ERROR" "$message"
}

# Based on code from: http://stackoverflow.com/a/16623897/483528
function strip_prefix {
  local readonly str="$1"
  local readonly prefix="$2"
  echo "${str#$prefix}"
}

function assert_not_empty {
  local readonly arg_name="$1"
  local readonly arg_value="$2"

  if [[ -z "$arg_value" ]]; then
    log_error "The value for '$arg_name' cannot be empty"
    print_usage
    exit 1
  fi
}

# Get the value at a specific Instance Metadata path.
function get_instance_metadata_value {
  local readonly path="$1"

  log_info "Looking up Metadata value at $COMPUTE_INSTANCE_METADATA_URL/$path"
  curl --silent --show-error --location --header "$GOOGLE_CLOUD_METADATA_REQUEST_HEADER" "$COMPUTE_INSTANCE_METADATA_URL/$path"
}

# Get the value of the given Custom Metadata Key
function get_instance_custom_metadata_value {
  local readonly key="$1"

  log_info "Looking up Custom Instance Metadata value for key \"$key\""
  get_instance_metadata_value "instance/attributes/$key"
}

# Get the ID of the Project in which this Compute Instance currently resides
function get_instance_project_id {
  log_info "Looking up Project ID"
  get_instance_metadata_value "project/project-id"
}

# Get the GCE Zone in which this Compute Instance currently resides
function get_instance_zone {
  log_info "Looking up Zone of the current Compute Instance"

  # The value returned for zone will be of the form "projects/121238320500/zones/us-west1-a" so we need to split the string
  # by "/" and return the 4th string.
  get_instance_metadata_value "instance/zone" | cut -d'/' -f4
}

function get_instance_region {
  # Trim the last two characters of a zone (e.g. us-west1-a) to get the region (e.g. us-west1)
  # Head command comes from https://unix.stackexchange.com/a/215156/129208
  get_instance_zone | head -c -3
}

# Get the ID of the current Compute Instance
function get_instance_name {
  log_info "Looking up current Compute Instance name"
  get_instance_metadata_value "instance/name"
}

# Get the IP Address of the current Compute Instance
function get_instance_ip_address {
  local network_interface_number="$1"

  # If no network interface number was specified, default to the first one
  if [[ -z "$network_interface_number" ]]; then
    network_interface_number=0
  fi

  log_info "Looking up Compute Instance IP Address on Network Interface $network_interface_number"
  get_instance_metadata_value "instance/network-interfaces/$network_interface_number/ip"
}

function assert_is_installed {
  local readonly name="$1"

  if [[ ! $(command -v ${name}) ]]; then
    log_error "The binary '$name' is required by this script but is not installed or in the system's PATH."
    exit 1
  fi
}

function generate_nomad_config {
  local readonly server="$1"
  local readonly client="$2"
  local readonly num_servers="$3"
  local readonly config_dir="$4"
  local readonly user="$5"
  local readonly cluster_tag_name="$6"
  local readonly enable_acls="$7"
  local readonly config_path="$config_dir/$NOMAD_CONFIG_FILE"

  local instance_name=""
  local instance_ip_address=""
  local instance_region=""
  local instance_zone=""

  instance_name=$(get_instance_name)
  instance_ip_address=$(get_instance_ip_address)
  instance_region=$(get_instance_region)
  zone=$(get_instance_zone)

  local server_config=""
  if [[ "$server" == "true" ]]; then
    server_config=$(cat <<EOF
server {
  enabled = true
  bootstrap_expect = $num_servers
}
EOF
)
  fi

  local server_join_config=""
  if [[ -z "$cluster_tag_name" ]]; then
    log_warn "The --cluster-tag-name property is empty. Will not automatically try to form a WAN cluster based on Cluster Tag Name."
  else
    server_join_config=$(cat <<EOF
server_join {
  retry_join = ["provider=gce project_name=methridge-sandbox tag_value=$cluster_tag_name"]
}
EOF
)
  fi

  local client_config=""
  if [[ "$client" == "true" ]]; then
    client_config=$(cat <<EOF
client {
  enabled = true
}
EOF
)
  fi

  local acl_config=""
  if [[ "$enable_acls" == "true" ]]; then
    acl_config=$( cat <<EOF
acl {
  enabled = true
}
EOF
)
fi

  log_info "Creating default Nomad config file in $config_path"
  cat > "$config_path" <<EOF
datacenter = "$zone"
name       = "$instance_name"
region     = "$instance_region"
bind_addr  = "0.0.0.0"

advertise {
  http = "$instance_ip_address"
  rpc  = "$instance_ip_address"
  serf = "$instance_ip_address"
}

$client_config

$server_config

$server_join_config

consul {
  address = "127.0.0.1:8500"
}

$acl_config
EOF
  chown "$user:$user" "$config_path"
}

function generate_supervisor_config {
  local readonly supervisor_config_path="$1"
  local readonly nomad_config_dir="$2"
  local readonly nomad_data_dir="$3"
  local readonly nomad_bin_dir="$4"
  local readonly nomad_log_dir="$5"
  local readonly nomad_user="$6"
  local readonly use_sudo="$7"

  if [[ "$use_sudo" == "true" ]]; then
    log_info "The --use-sudo flag is set, so running Nomad as the root user"
    nomad_user="root"
  fi

  log_info "Creating Supervisor config file to run Nomad in $supervisor_config_path"
  cat > "$supervisor_config_path" <<EOF
[program:nomad]
command=$nomad_bin_dir/nomad agent -config $nomad_config_dir -data-dir $nomad_data_dir
stdout_logfile=$nomad_log_dir/nomad-stdout.log
stderr_logfile=$nomad_log_dir/nomad-error.log
numprocs=1
autostart=true
autorestart=true
stopsignal=INT
user=$nomad_user
EOF
}

function start_nomad {
  log_info "Reloading Supervisor config and starting Nomad"
  supervisorctl reread
  supervisorctl update
}

# Based on: http://unix.stackexchange.com/a/7732/215969
function get_owner_of_path {
  local readonly path="$1"
  ls -ld "$path" | awk '{print $3}'
}

function run {
  local server="false"
  local client="false"
  local enable_acls="false"
  local num_servers=""
  local config_dir=""
  local data_dir=""
  local bin_dir=""
  local log_dir=""
  local user=""
  local cluster_tag_name=""
  local skip_nomad_config="false"
  local use_sudo=""
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
        enable_acls="true"
        ;;
      --num-servers)
        num_servers="$2"
        shift
        ;;
      --config-dir)
        assert_not_empty "$key" "$2"
        config_dir="$2"
        shift
        ;;
      --data-dir)
        assert_not_empty "$key" "$2"
        data_dir="$2"
        shift
        ;;
      --bin-dir)
        assert_not_empty "$key" "$2"
        bin_dir="$2"
        shift
        ;;
      --log-dir)
        assert_not_empty "$key" "$2"
        log_dir="$2"
        shift
        ;;
      --user)
        assert_not_empty "$key" "$2"
        user="$2"
        shift
        ;;
      --cluster-tag-name)
        cluster_tag_name="$2"
        shift
        ;;
      --skip-nomad-config)
        skip_nomad_config="true"
        ;;
      --use-sudo)
        use_sudo="true"
        ;;
      --help)
        print_usage
        exit
        ;;
      *)
        log_error "Unrecognized argument: $key"
        print_usage
        exit 1
        ;;
    esac

    shift
  done

  if [[ "$server" == "true" ]]; then
    assert_not_empty "--num-servers" "$num_servers"
  fi

  if [[ "$server" == "false" && "$client" == "false" ]]; then
    log_error "At least one of --server or --client must be set"
    exit 1
  fi

  if [[ -z "$use_sudo" ]]; then
    if [[ "$client" == "true" ]]; then
      use_sudo="true"
    else
      use_sudo="false"
    fi
  fi

  assert_is_installed "supervisorctl"
  assert_is_installed "curl"

  if [[ -z "$config_dir" ]]; then
    config_dir=$(cd "$SCRIPT_DIR/../config" && pwd)
  fi

  if [[ -z "$data_dir" ]]; then
    data_dir=$(cd "$SCRIPT_DIR/../data" && pwd)
  fi

  if [[ -z "$bin_dir" ]]; then
    bin_dir=$(cd "$SCRIPT_DIR/../bin" && pwd)
  fi

  if [[ -z "$log_dir" ]]; then
    log_dir=$(cd "$SCRIPT_DIR/../log" && pwd)
  fi

  if [[ -z "$user" ]]; then
    user=$(get_owner_of_path "$config_dir")
  fi

  if [[ "$skip_nomad_config" == "true" ]]; then
    log_info "The --skip-nomad-config flag is set, so will not generate a default Nomad config file."
  else
    generate_nomad_config "$server" "$client" "$num_servers" "$config_dir" "$user" "$cluster_tag_name" "$enable_acls"
  fi

  generate_supervisor_config "$SUPERVISOR_CONFIG_PATH" "$config_dir" "$data_dir" "$bin_dir" "$log_dir" "$user" "$use_sudo"
  start_nomad
}

run "$@"