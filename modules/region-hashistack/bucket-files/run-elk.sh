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

function install_elk {
  # Install Java
  sudo apt-get --quiet --assume-yes install openjdk-8-jre-headless 
  # sudo apt-get --quiet --assume-yes install openjdk-11-jre-headless 
  # sudo echo 'JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64/bin/java"' >> /etc/environment
  # JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64/bin/java"

  # Add the influxdata signing key
  curl -sSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

  sudo apt-get install apt-transport-https

  # Configure a package repo
  source /etc/lsb-release
  echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
  
  # Install ELK
  sudo apt-get update 
  sudo apt-get --quiet --assume-yes install elasticsearch kibana logstash
}

function generate_elk_config {
  cat >> "/etc/kibana/kibana.yml" <<EOF
server.host: "0.0.0.0"
EOF

  cat > "/etc/logstash/conf.d/sandbox.conf" <<EOF
input {
  beats {
    port => 5044
  }
}

filter {
  if [fields][type] == "consul_logs" {
    mutate { add_field => { "[@metadata][target_index]" => "consul-logs-%{+yyyy.MM.dd}" } }
  } else if [fields][type] == "vault_logs" {
    mutate { add_field => { "[@metadata][target_index]" => "vault-logs-%{+yyyy.MM.dd}" } }
  } else {
    mutate { add_field => { "[@metadata][target_index]" => "unknown-%{+yyyy.MM.dd}" } }
  }
}

output {
  elasticsearch {
    hosts => ["http://localhost:9200"]
    index => "%{[@metadata][target_index]}"
  }
}
EOF
}

function start_elk {
  systemctl daemon-reload
  systemctl enable elasticsearch
  systemctl enable kibana
  systemctl enable logstash
  systemctl restart elasticsearch
  systemctl restart kibana
  systemctl restart logstash
}

function run {
  local product=""

  while [[ $# > 0 ]]; do
    local key="$1"

    case "$key" in
      --product)
        product="$2"
        shift
        ;;
    esac

    shift
  done

  install_elk
  generate_elk_config
  start_elk
}

run "$@"