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

# Get the GCE Zone in which this Compute Instance currently resides
function get_instance_zone {
  get_instance_metadata_value "instance/zone" | cut -d'/' -f4
}

# Get the GCE Region in which this Compute Instance currently resides
function get_instance_region {
  get_instance_zone | head -c -3
}

function install_telegraf {
  # Add the influxdata signing key
  curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -

  # Configure a package repo
  source /etc/lsb-release
  echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
  
  # Install Telegraf
  sudo apt-get update 
  sudo apt-get install telegraf
}

function generate_telegraf_config {
  local -r consul="$1"
  local -r vault="$2"

  local role=""

  instance_region=$(get_instance_region)

  if [[ "$consul" == "true" ]]; then
    role="consul-server"
  elif [[ "$vault" == "true" ]]; then
    role="vault-server"
  else
    echo "Unknown telegraf role"
    exit 1
  fi

  # Configure Telegraf
  cat > "/etc/telegraf/telegraf.conf" <<EOF
# Vault Config
[agent]
  interval = "10s"
  flush_interval = "10s"
  omit_hostname = false
[global_tags]
  role = "$role"
  datacenter = "$instance_region"
[[inputs.statsd]]
  protocol = "udp"
  service_address = ":8125"
  delete_gauges = true
  delete_counters = true
  delete_sets = true
  delete_timings = true
  percentiles = [90]
  metric_separator = "_"
  datadog_extensions = true
  allowed_pending_messages = 10000
  percentile_limit = 1000
[[inputs.cpu]]
  percpu = true
  totalcpu = true
  collect_cpu_time = false
[[inputs.disk]]
  # mount_points = ["/"]
  # ignore_fs = ["tmpfs", "devtmpfs"]
[[inputs.diskio]]
  # devices = ["sda", "sdb"]
  # skip_serial_number = false
[[inputs.kernel]]
  # no configuration
[[inputs.linux_sysctl_fs]]
  # no configuration
[[inputs.mem]]
  # no configuration
[[inputs.net]]
  # interfaces = ["eth1"]
[[inputs.netstat]]
  # no configuration
[[inputs.processes]]
  # no configuration
[[inputs.procstat]]
  pattern = "(consul|vault)"
[[inputs.swap]]
  # no configuration
[[inputs.system]]
  # no configuration
[[inputs.consul]]
  address = "localhost:8500"
  scheme = "http"
  # token = ""
  # datacenter = ""
  # tls_ca = "/etc/telegraf/ca.pem"
  # tls_cert = "/etc/telegraf/cert.pem"
  # tls_key = "/etc/telegraf/key.pem"
  # insecure_skip_verify = true

[[outputs.prometheus_client]]
  ## Address to listen on.
  listen = ":9273"
  metric_version = 2
EOF
}

function start_telegraf {
  systemctl daemon-reload
  systemctl enable telegraf
  systemctl restart telegraf
}

function run {
  local consul="false"
  local vault="false"

  while [[ $# > 0 ]]; do
    local key="$1"

    case "$key" in
      --consul)
        consul="true"
        ;;
      --vault)
        vault="true"
        ;;
    esac

    shift
  done

  if [[ ("$consul" == "true" && "$vault" == "true") ||
        ("$consul" == "false" && "$vault" == "false") ]]; then
    exit 1
  fi

  install_telegraf
  generate_telegraf_config "$consul" "$vault"
  start_telegraf
}

run "$@"