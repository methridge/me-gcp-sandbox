#!/usr/bin/env bash
set -e

# Variables Needed
## Premium Binary Bucket

export DEBIAN_FRONTEND=noninteractive

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
  sudo apt-get --quiet --assume-yes upgrade
  sudo apt-get --quiet --assume-yes dist-upgrade
  sudo apt-get --quiet --assume-yes autoremove
  sudo apt-get --quiet --assume-yes install curl unzip jq
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
  sudo mkdir --parents /opt/$app/log
  sudo mkdir --parents /opt/$app/tls
  sudo chown --recursive $app:$app /opt/$app
}

function install_binaries {
  local prem_bucket="$1"
  local product="$2"
  local version="$3"
  local ent="$4"
  local prem="$5"

  if [[ ($ent == "true" && $prem == "true") ]]; then
    log_error "Either --ent or --prem must be set, not both."
    exit 1
  fi

  if [[ ${version} == "" ]]; then
    version=$(jq -r ".\"${product}\".versions | keys | .[]" /tmp/index.json \
      | grep -v 'oci\|hsm\|ent\|beta\|rc' \
      | sort --version-sort \
      | tail -n1)
  fi

  if [[ ${version} == *"-"* ]] && [[ ${ent} ]] && [[ ${product} == "consul" ]]; then
    version="${version/-/+ent-}"
  elif [[ ${ent} == "true" ]]; then
    version="${version}+ent"
  fi

  local -r url="https://releases.hashicorp.com/${product}/${version}/${product}_${version}_linux_amd64.zip"
  local -r bin_dir="/usr/local/bin"
  local -r dest_path="${bin_dir}/${product}"

  if [[ ${prem} = "true" ]]; then
    log_info "Installing Premium Version"
    if [[ ${product} == "nomad" ]]; then
      log_info "From: gs://${prem_bucket}/${product}/${version}/${product}-enterprise_${version}+ent_linux_amd64.zip"
      /snap/bin/gsutil cp \
      gs://${prem_bucket}/${product}/${version}/${product}-enterprise_${version}+ent_linux_amd64.zip \
      /tmp/${product}.zip
    else
      log_info "From: gs://${prem_bucket}/${product}/${version}/${product}-enterprise_${version}+prem_linux_amd64.zip"
      /snap/bin/gsutil cp \
      gs://${prem_bucket}/${product}/${version}/${product}-enterprise_${version}+prem_linux_amd64.zip \
      /tmp/${product}.zip
    fi
  else
    log_info "Installing Releases Version"
    log_info "from url: https://releases.hashicorp.com/${product}/${version}/${product}_${version}_linux_amd64.zip"
    curl --silent --output /tmp/${product}.zip \
    https://releases.hashicorp.com/${product}/${version}/${product}_${version}_linux_amd64.zip
  fi

  unzip -d /tmp /tmp/${product}.zip

  log_info "Moving $product binary to ${dest_path}"
  sudo mv "/tmp/${product}" "${dest_path}"
  sudo chown "root:root" "${dest_path}"
  sudo chmod a+x "${dest_path}"
}

function copy_consul_certs {
  log_info "Copying Consul Certs"
  sudo mv /tmp/files/consul-tls/*.pem /opt/consul/tls/
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
  sudo mv /tmp/files/${product}.service /etc/systemd/system/${product}.service
  sudo chown root:root /etc/systemd/system/${product}.service
  sudo chmod 644 /etc/systemd/system/${product}.service
}

function configure_mlock {
  log_info "Giving Vault permission to use the mlock syscall"
  sudo setcap cap_ipc_lock=+ep /usr/local/bin/vault
}

function copy_vault_certs {
  log_info "Copying Vault Certs"
  sudo mv /tmp/files/vault-ca.pem /opt/vault/tls/ca.crt.pem
  sudo mv /tmp/files/vault.pem /opt/vault/tls/vault.crt.pem
  sudo mv /tmp/files/vault-key.pem /opt/vault/tls/vault.key.pem
  sudo cp /opt/vault/tls/ca.crt.pem /usr/local/share/ca-certificates/custom.crt
  sudo update-ca-certificates
}

function run_consul {
  local -r consul_mode="$1"
  local -r consul_cluster_tag_name="$2"
  local -r consul_cluster_wan_join_tag="$3"

  if [[ (${consul_mode} == "server" || ${consul_mode} == "client") ]]; then
    log_info "Starting Consul in $consul_mode mode"
    sudo mv /tmp/files/run-consul.sh /usr/local/bin/run-consul.sh
    sudo chmod a+x /usr/local/bin/run-consul.sh
    /usr/local/bin/run-consul.sh \
      --${consul_mode} \
      --cluster-tag-name "${consul_cluster_tag_name}" \
      --cluster-wan-join-tag "${consul_cluster_wan_join_tag}"
  else
    log_info "Unknown Consul mode: $consul_mode, not starting Consul"
  fi
}

function run_vault {
  local -r vault_mode="$1"
  local -r vault_storage="$2"
  local -r vault_auto_unseal_key_project_id="$3"
  local -r vault_auto_unseal_key_region="$4"
  local -r vault_auto_unseal_key_ring="$5"
  local -r vault_auto_unseal_crypto_key_name="$6"

  if [[ ${vault_mode} == "server" ]]; then
    if [[ ${vault_auto_unseal_key_project_id} == "" ||
          ${vault_auto_unseal_key_region} == "" ||
          ${vault_auto_unseal_key_ring} == "" ||
          ${vault_auto_unseal_crypto_key_name} == "" ]];then
      log_error "Auto Unseal parameters missing"
      exit 1
    fi
    log_info "Starting Vault in server mode"
    sudo mv /tmp/files/run-vault.sh /usr/local/bin/run-vault.sh
    sudo chmod a+x /usr/local/bin/run-vault.sh
    /usr/local/bin/run-vault.sh \
      --vault-storage "${vault_storage}" \
      --tls-cert-file "/opt/vault/tls/vault.crt.pem" \
      --tls-key-file "/opt/vault/tls/vault.key.pem" \
      --auto-unseal-key-project-id "${vault_auto_unseal_key_project_id}" \
      --auto-unseal-key-region "${vault_auto_unseal_key_region}" \
      --auto-unseal-key-ring "${vault_auto_unseal_key_ring}" \
      --auto-unseal-crypto-key-name "${vault_auto_unseal_crypto_key_name}"
  elif [[ ${vault_mode} == "agent" ]]; then
    log_info "Starting Vault in agent mode"
    sudo mv /tmp/files/run-vault.sh /usr/local/bin/run-vault.sh
    sudo chmod a+x /usr/local/bin/run-vault.sh
    /usr/local/bin/run-vault.sh --vault-mode="${vault_mode}"
  else
    log_info "Unknown Vault mode, not starting Vault"
  fi
}

function run_nomad {
  local -r nomad_mode="$1"
  local -r nomad_acl_enabled="$2"
  local -r num_servers="$3"
  local -r nomad_cluster_tag_name="$4"

  if [[ ($nomad_mode == "server" || $nomad_mode == "client") ]]; then
    log_info "Starting Nomad in $nomad_mode mode"
    sudo mv /tmp/files/run-nomad.sh /usr/local/bin/run-nomad.sh
    sudo chmod a+x /usr/local/bin/run-nomad.sh
    /usr/local/bin/run-nomad.sh \
      --${nomad_mode} \
      --enable-acls "${nomad_acl_enabled}" \
      --num-servers "${num_servers}" \
      --cluster-tag-name "${nomad_cluster_tag_name}"
  else
    log_info "Unknown Nomad mode, not starting Nomad"
  fi
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

function install {
  local prem_bucket=""
  local consul_mode=""
  local consul_version=""
  local consul_ent="false"
  local consul_prem="false"
  local consul_cluster_tag_name=""
  local vault_mode=""
  local vault_storage="raft"
  local vault_version=""
  local vault_ent="false"
  local vault_prem="false"
  local vault_auto_unseal_key_project_id=""
  local vault_auto_unseal_key_region=""
  local vault_auto_unseal_key_ring=""
  local vault_auto_unseal_crypto_key_name=""
  local nomad_mode=""
  local nomad_version=""
  local nomad_ent="false"
  local nomad_prem="false"
  local nomad_num_servers="3"
  local nomad_cluster_tag_name=""
  local nomad_acl_enabled="false"
  local consul_template=""
  local envconsul=""
  local terraform=""
  local elk_stack="false"

  while [[ $# > 0 ]]; do
    local key="$1"

    case "$key" in
      --prem-bucket)
        prem_bucket="$2"
        shift
        ;;
      --consul-mode)
        consul_mode="$2"
        shift
        ;;
      --consul-version)
        consul_version="$2"
        shift
        ;;
      --consul-ent)
        consul_ent="$2"
        shift
        ;;
      --consul-prem)
        consul_prem="$2"
        shift
        ;;
      --consul-cluster-tag-name)
        consul_cluster_tag_name="$2"
        shift
        ;;
      --consul-cluster-wan-join-tag)
        consul_cluster_wan_join_tag="$2"
        shift
        ;;
      --vault-mode)
        vault_mode="$2"
        shift
        ;;
      --vault-storage)
        vault_storage="$2"
        shift
        ;;
      --vault-version)
        vault_version="$2"
        shift
        ;;
      --vault-ent)
        vault_ent="$2"
        shift
        ;;
      --vault-prem)
        vault_prem="$2"
        shift
        ;;
      --auto-unseal-key-project-id)
        vault_auto_unseal_key_project_id="$2"
        shift
        ;;
      --auto-unseal-key-region)
        vault_auto_unseal_key_region="$2"
        shift
        ;;
      --auto-unseal-key-ring)
        vault_auto_unseal_key_ring="$2"
        shift
        ;;
      --auto-unseal-crypto-key-name)
        vault_auto_unseal_crypto_key_name="$2"
        shift
        ;;
      --nomad-mode)
        nomad_mode="$2"
        shift
        ;;
      --nomad-version)
        nomad_version="$2"
        shift
        ;;
      --nomad-ent)
        nomad_ent="$2"
        shift
        ;;
      --nomad-prem)
        nomad_prem="$2"
        shift
        ;;
      --nomad-num-servers)
        nomad_num_servers="$2"
        shift
        ;;
      --nomad-cluster-tag-name)
        nomad_cluster_tag_name="$2"
        shift
        ;;
      --nomad-acl-enabled)
        nomad_acl_enabled="$2"
        shift
        ;;
      --consul-template)
        consul_template="$2"
        shift
        ;;
      --envconsul)
        envconsul="$2"
        shift
        ;;
      --terraform)
        terraform="$2"
        shift
        ;;
      --elk-stack)
        elk_stack="$2"
        shift
        ;;
      *)
        log_error "Unrecognized argument: $key"
        exit 1
        ;;
    esac

    shift
  done

  log_info "Starting Hashistack install"

  log_info "Installing Dependancies"
  install_dependancies

  log_info "Installing Consul"
  create_user "consul"
  create_install_paths "consul"
  install_binaries "$prem_bucket" "consul" "$consul_version" "$consul_ent" "$consul_prem"
  copy_consul_certs
  install_dnsmasq
  configure_dnsmasq_resolv
  create_service "consul"
  run_consul "$consul_mode" "$consul_cluster_tag_name" "$consul_cluster_wan_join_tag"
  log_info "Consul install completed"

  log_info "Installing Vault"
  create_user "vault"
  create_install_paths "vault"
  install_binaries "$prem_bucket" "vault" "$vault_version" "$vault_ent" "$vault_prem"
  create_service "vault"
  copy_vault_certs
  run_vault "$vault_mode" "$vault_storage" "$vault_auto_unseal_key_project_id" "$vault_auto_unseal_key_region" "$vault_auto_unseal_key_ring" "$vault_auto_unseal_crypto_key_name"
  log_info "Vault install completed"

  log_info "Installing Nomad"
  create_user "nomad"
  create_install_paths "nomad"
  install_binaries "$prem_bucket" "nomad" "$nomad_version" "$nomad_ent" "$nomad_prem"
  create_service "nomad"
  run_nomad "$nomad_mode" "$nomad_acl_enabled" "$nomad_num_servers" "$nomad_cluster_tag_name"
  log_info "Nomad install complete"

  log_info "Installing additional HashiCorp products"
  install_binaries "" "consul-template" "$consul_template" "" ""
  install_binaries "" "envconsul" "$envconsul" "" ""
  install_binaries "" "terraform" "$terraform" "" ""
  log_info "Completed install of additional HashiCorp products"

  if [[ $elk_stack == "true" ]]; then
    log_info "Installing Telegraf"
    run_telegraf "$consul_mode" "$vault_mode"
    log_info "Completed Telegraf install"

    log_info "Installing Filebeat"
    run_filebeat "$vault_mode"
    log_info "Completed Filebeat install"
  fi

  log_info "Hashistack install complete!"
}

install "$@"
