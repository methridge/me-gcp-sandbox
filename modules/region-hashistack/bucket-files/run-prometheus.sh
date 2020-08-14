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

function install_prometheus {
  sudo apt-get install -y apt-transport-https
  sudo apt-get install -y software-properties-common wget
  wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
  sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
  sudo apt-get update
  sudo apt-get install grafana

  sudo useradd --no-create-home --shell /bin/false prometheus

  sudo mkdir -p /etc/prometheus
  sudo mkdir -p /var/lib/prometheus/
  sudo chown -R prometheus:prometheus /etc/prometheus
  sudo chown -R prometheus:prometheus /var/lib/prometheus

  curl -sLo /tmp/prometheus.tar.gz https://github.com/prometheus/prometheus/releases/download/v2.19.2/prometheus-2.19.2.linux-amd64.tar.gz
  tar xvfz /tmp/prometheus.tar.gz --directory /tmp
  rm /tmp/prometheus.tar.gz

  sudo cp /tmp/prometheus-*/prometheus /usr/local/bin/
  sudo cp /tmp/prometheus-*/promtool /usr/local/bin/
  sudo chown prometheus:prometheus /usr/local/bin/prometheus
  sudo chown prometheus:prometheus /usr/local/bin/promtool

  sudo cp -r /tmp/prometheus-*/consoles /etc/prometheus
  sudo cp -r /tmp/prometheus-*/console_libraries /etc/prometheus
  sudo chown -R prometheus:prometheus /etc/prometheus/consoles
  sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries
}

function get_consul_hosts {
  curl -s http://127.0.0.1:8500/v1/catalog/service/consul | jq -r '.[].Address'
}

function get_vault_hosts {
  curl -s http://127.0.0.1:8500/v1/catalog/service/vault | jq -r '.[].Address'
}

function generate_prometheus_config {
  readarray -t consulhosts < <(get_consul_hosts)
  readarray -t vaulthosts < <(get_vault_hosts)

  cat > "/etc/prometheus/prometheus.yml" <<EOF
global:
  scrape_interval:     10s
  evaluation_interval: 10s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
    - targets: ['localhost:9090']

  - job_name: 'vault-server'
    static_configs:
    - targets: ['${vaulthosts[0]}:9273']
    scheme: "http"
    tls_config:
      insecure_skip_verify: true
    metrics_path: "/metrics"
    params:
      format: ['prometheus']

  - job_name: 'consul-1-server'
    static_configs:
    - targets: ['${consulhosts[0]}:9273']
    scheme: "http"
    tls_config:
      insecure_skip_verify: true
    metrics_path: "/metrics"
    params:
      format: ['prometheus']

  - job_name: 'consul-2-server'
    static_configs:
    - targets: ['${consulhosts[1]}:9273']
    scheme: "http"
    tls_config:
      insecure_skip_verify: true
    metrics_path: "/metrics"
    params:
      format: ['prometheus']

  - job_name: 'consul-3-server'
    static_configs:
    - targets: ['${consulhosts[2]}:9273']
    scheme: "http"
    tls_config:
      insecure_skip_verify: true
    metrics_path: "/metrics"
    params:
      format: ['prometheus']
EOF
}

function start_prometheus {
cat > "/etc/systemd/system/prometheus.service" <<EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable prometheus
systemctl enable grafana-server
systemctl start prometheus
systemctl start grafana-server
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

  install_prometheus
  generate_prometheus_config
  start_prometheus
}

run "$@"