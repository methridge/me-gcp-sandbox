#!/usr/bin/env bash

set -e

export DEBIAN_FRONTEND=noninteractive

readonly COMPUTE_INSTANCE_METADATA_URL="http://metadata.google.internal/computeMetadata/v1"
readonly GOOGLE_CLOUD_METADATA_REQUEST_HEADER="Metadata-Flavor: Google"

# Get the value at a specific Instance Metadata path.
function get_instance_metadata_value {
  local -r path="$1"
  curl --silent --show-error --location --header "$GOOGLE_CLOUD_METADATA_REQUEST_HEADER" "$COMPUTE_INSTANCE_METADATA_URL/$path"
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

function install_filebeat {
  # Add the influxdata signing key
  curl -sSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

  sudo apt-get install apt-transport-https

  # Configure a package repo
  source /etc/lsb-release
  echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
  
  # Install Filebeat
  sudo apt-get update 
  sudo apt-get install filebeat
}

function generate_filebeat_config {
  local product="$1"

  instance_region=$(get_instance_region)
  project_id=$(get_instance_project_id)

    cat > "/etc/filebeat/filebeat.yml" <<EOF
output:
  logstash:
    enabled: true
    hosts:
      - logstash.service.consul:5044
    timeout: 15

filebeat:
  inputs:
    - type: log
      json.keys_under_root: true
      paths:
        - "/opt/consul/log/*.json"
      fields:
        type: consul_logs
EOF

  if [[ "$product" != "" ]]; then
    cat >> "/etc/filebeat/filebeat.yml" <<EOF
    - type: log
      json.keys_under_root: true
      paths:
        - "/opt/${product}/log/*.json"
      fields:
        type: ${product}_logs
EOF
  fi
}

function start_filebeat {
  systemctl daemon-reload
  systemctl enable filebeat
  systemctl restart filebeat
}

function run {
  local vault="false"

  while [[ $# > 0 ]]; do
    local key="$1"

    case "$key" in
      --vault)
        vault="true"
        ;;
    esac

    shift
  done

  install_filebeat
  if [[ "$vault" == "true" ]]; then
    generate_filebeat_config "vault"
  else
    generate_filebeat_config ""
  fi
  start_filebeat
}

run "$@"