#!/usr/bin/env bash
set -e

export DEBIAN_FRONTEND=noninteractive
echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections

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

function install_dependancies {
  log_info "Installing dependancies"
  sudo apt-get --quiet --assume-yes update
  sudo apt-get --quiet --assume-yes dist-upgrade
  sudo apt-get --quiet --assume-yes autoremove
  sudo apt-get --quiet --assume-yes install curl unzip jq net-tools docker.io default-jre

  # Install CNI
  curl -sSL -o /tmp/cni-plugins.tgz https://github.com/containernetworking/plugins/releases/download/v0.8.6/cni-plugins-linux-amd64-v0.8.6.tgz
  sudo mkdir -p /opt/cni/bin
  sudo tar -C /opt/cni/bin -xzf /tmp/cni-plugins.tgz

  log_info "Dependancies Installed"

  log_info "Downloading Versions JSON"
  curl -sSL -o /tmp/index.json https://releases.hashicorp.com/index.json
}

function user_exists {
  local -r username="$1"
  id "$username" >/dev/null 2>&1
}

function create_user {
  local -r user="$1"
  if $(user_exists "$user"); then
    echo "User $user already exists. Will not create again."
  else
    log_info "Creating user named $user"
    sudo useradd --system --home /etc/$user.d --shell /bin/false $user
  fi
}

function create_install_paths {
  local -r app="$1"
  log_info "Creating install dirs for $app"
  sudo mkdir --parents /etc/$app.d
  sudo mkdir --parents /opt/$app/data
  sudo mkdir --parents /opt/$app/lic
  sudo mkdir --parents /opt/$app/log
  sudo mkdir --parents /opt/$app/tls
  sudo chown --recursive $app:$app /opt/$app
}

function install_binaries {
  local product="$1"
  local version="$2"
  local ent="$3"

  if [[ ${version} == "" ]]; then
    version=$(jq -r ".\"${product}\".versions | keys | .[]" /tmp/index.json \
      | grep -v 'alpha\|beta\|ent\|hsm\|oci\|rc' \
      | sort --version-sort \
      | tail -n1)
  fi

  if [[ ${version} == *"-"* ]] && [[ ${ent} ]] && [[ ${product} == "consul" ]]; then
    version="${version/-/+ent-}"
  elif [[ ${ent} == "true" ]]; then
    version="${version}+ent"
  fi

  local -r url="https://releases.hashicorp.com/${product}/${version}/${product}_${version}_linux_amd64.zip"
  local -r bin_dir="/usr/bin"
  local -r dest_path="${bin_dir}/${product}"

  log_info "Installing Releases Version"
  log_info "from url: https://releases.hashicorp.com/${product}/${version}/${product}_${version}_linux_amd64.zip"
  curl --silent --output /tmp/${product}.zip \
  https://releases.hashicorp.com/${product}/${version}/${product}_${version}_linux_amd64.zip

  unzip -d /tmp /tmp/${product}.zip

  log_info "Moving ${product} binary to ${dest_path}"
  sudo mv "/tmp/${product}" "${dest_path}"
  sudo chown "root:root" "${dest_path}"
  sudo chmod a+x "${dest_path}"
}

function install_license {
  local product="$1"

  log_info "Placing ${product} license file in /opt/${product}/lic"
  sudo mv "/tmp/licenses/${product}.hclic" "/opt/${product}/lic/${product}.hclic"
}

function install_dnsmasq {
  log_info "Installing Dnsmasq and ResolvConf"
  sudo apt-get --quiet --assume-yes install dnsmasq resolvconf
}

function configure_dnsmasq_resolv {
  log_info "Configuring Dnsmasq and ResolvConf"
  # Configure dnsmasq
  sudo mkdir --parents /etc/dnsmasq.d
  sudo mv /tmp/files/10-consul /etc/dnsmasq.d/10-consul

  # Setup resolv to use dnsmasq for consul
  sudo mkdir --parents /etc/resolvconf/resolv.conf/
  sudo mv /tmp/files/head /etc/resolvconf/resolv.conf/head
  sudo systemctl enable resolvconf
  sudo systemctl start resolvconf
  sudo systemctl restart dnsmasq
}

function create_service {
  local -r product="$1"

  log_info "Configuring ${product} Service"
  sudo mv /tmp/files/${product}.service /usr/lib/systemd/system/${product}.service
  sudo chown root:root /usr/lib/systemd/system/${product}.service
  sudo chmod 644 /usr/lib/systemd/system/${product}.service

  sudo mv /tmp/files/run-${product}.sh /usr/local/bin/run-${product}.sh
  sudo chown root:root /usr/local/bin/run-${product}.sh
  sudo chmod a+x /usr/local/bin/run-${product}.sh
}

function configure_mlock {
  log_info "Giving Vault permission to use the mlock syscall"
  sudo setcap cap_ipc_lock=+ep /usr/local/bin/vault
}

function run_telegraf {
  local -r consul="$1"
  local -r vault="$2"

  sudo mv /tmp/files/run-telegraf.sh /usr/local/bin/run-telegraf.sh
  sudo chmod a+x /usr/local/bin/run-telegraf.sh
  if [[ "$consul" == "server" ]]; then
    log_info "Installing Telegraf for Consul"
    /usr/local/bin/run-telegraf.sh --consul
  elif [[ "$vault" == "server" ]]; then
    log_info "Installing Telegraf for Vault"
    /usr/local/bin/run-telegraf.sh --vault
  else
    log_info "Not Installing Telegraf"
  fi
}

function run_filebeat {
  local -r vault="$1"

  sudo mv /tmp/files/run-filebeat.sh /usr/local/bin/run-filebeat.sh
  sudo chmod a+x /usr/local/bin/run-filebeat.sh
  if [[ "$vault" == "server" ]]; then
    log_info "Installing filebeat for Vault"
    /usr/local/bin/run-filebeat.sh --vault
  else
    log_info "Installing Filebeat for Consul Only"
    /usr/local/bin/run-filebeat.sh
  fi
}

function install_envoy {
  log_info "Installing Envoy Proxy"

  sudo apt-get --quiet --assume-yes install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

  curl -sL 'https://getenvoy.io/gpg' | sudo apt-key add -

  sudo add-apt-repository \
    "deb [arch=amd64] https://dl.bintray.com/tetrate/getenvoy-deb \
    $(lsb_release -cs) \
    stable"

  sudo apt-get --quiet --assume-yes update
  sudo apt-get --quiet --assume-yes install getenvoy-envoy=1.14.4.p0.g923c411-1p67.g2aa564b
}

function install {
  log_info "Starting Hashistack install"

  log_info "Installing Dependancies"
  install_dependancies

  log_info "Installing Consul"
  create_user "consul"
  create_install_paths "consul"
  install_binaries "consul" "${CONSUL_VERSION}" "${CONSUL_ENT}"
  install_license "consul"
  install_dnsmasq
  configure_dnsmasq_resolv
  create_service "consul"
  log_info "Consul install completed"

  log_info "Installing Vault"
  create_user "vault"
  create_install_paths "vault"
  install_binaries "vault" "${VAULT_VERSION}" "${VAULT_ENT}"
  install_license "vault"
  create_service "vault"
  log_info "Vault install completed"

  log_info "Installing Nomad"
  create_user "nomad"
  create_install_paths "nomad"
  install_binaries "nomad" "${NOMAD_VERSION}" "${NOMAD_ENT}"
  install_license "nomad"
  create_service "nomad"
  log_info "Nomad install complete"

  log_info "Installing additional HashiCorp products"
  install_binaries "consul-template" "${CONSUL_TEMPLATE_VERSION}" ""
  install_binaries "envconsul" "${ENVCONSUL_VERSION}" ""
  install_binaries "terraform" "${TERRAFORM_VERSION}" ""
  log_info "Completed install of additional HashiCorp products"

  log_info "Installing Envoy Proxy"
  install_envoy
  log_info "Completed install of Envoy Proxy"

  if [[ $elk_stack == "true" ]]; then
    log_info "Installing Telegraf"
    run_telegraf "$consul_mode" "$vault_mode"
    log_info "Completed Telegraf install"

    log_info "Installing Filebeat"
    run_filebeat "$vault_mode"
    log_info "Completed Filebeat install"
  fi

  echo 'debconf debconf/frontend select Dialog' | sudo debconf-set-selections
  log_info "Hashistack install complete!"
}

install "$@"
