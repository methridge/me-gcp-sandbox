#!/bin/zsh
readonly mypath=$0:h
readonly _cwd=${PWD}
readonly ETC_HOSTS=/etc/hosts
readonly products=("consul" "nomad" "vault")

function log {
  local -r level="$1"
  local -r message="$2"
  local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S")

  local -r bldred="\033[0;31m" # Red
  local -r bldgrn="\033[0;32m" # Green
  local -r bldylw="\033[0;33m" # Yellow
  local -r bldblu="\033[0;34m" # Blue
  local -r bldpur="\033[0;35m" # Purple
  local -r bldcyn="\033[0;36m" # Cyan
  local -r bldwht="\033[0;37m" # White
  local -r txtrst="\033[0m"    # Text Reset
  
  local COL=""

  if [[ "${level}" == "INFO" ]]; then
    COL=${bldgrn}
  elif [[ "${level}" == "ERROR" ]]; then
    COL=${bldred}
  elif [[ "${level}" == "WARN" ]]; then
    COL=${bldylw}
  fi
  >&2 echo -e "${bldcyn}${timestamp}${txtrst} [${COL}${level}${txtrst}] ${message}"
}

# A retry function that attempts to run a command a number of times and returns the output
function retry {
  local -r cmd="$1"
  local -r description="$2"

  for i in $(seq 1 30); do
    log "INFO" "$description"

    output=$(eval "$cmd") && exit_status=0 || exit_status=$?
    log "INFO" "$output"
    if [[ $exit_status -eq 0 ]]; then
      log "ERROR" "$output"
      return
    fi
    log "INFO" "$description failed. Will sleep for 10 seconds and try again."
    sleep 10
  done;

  log "ERROR" "$description failed after 30 attempts."
  exit $exit_status
}

function hostUpdate {
  HOSTS_LINE="${1}\t${2}.${DNS_ZONE}"
  if [ -n "$(grep ${2}.${DNS_ZONE} ${ETC_HOSTS})" ]; then
    log "WARN" "${2}.${DNS_ZONE} Found in your ${ETC_HOSTS}, Removing now...";
    sudo sed -i".bak" "/${2}.${DNS_ZONE}/d" ${ETC_HOSTS}
  fi
  log "INFO" "Adding ${2}.${DNS_ZONE} to your ${ETC_HOSTS}";
  sudo -- sh -c -e "echo '${HOSTS_LINE}' >> ${ETC_HOSTS}";
  if [ -n "$(grep ${2}.${DNS_ZONE} ${ETC_HOSTS})" ]; then
    log "INFO" "${2}.${DNS_ZONE} was added succesfully \n $(grep ${2}.${DNS_ZONE} ${ETC_HOSTS})";
  else
    log "ERROR" "Failed to Add ${2}.${DNS_ZONE}, Try again!";
  fi
}

# Update hosts file
hostUpdate ${LB_IP} "lb"
for product in ${products[@]}; do
  hostUpdate ${GLB_IP} ${product}
done

export CONSUL_CACERT=${_cwd}/.tmp/sandbox-ca.pem
export CONSUL_CLIENT_CERT=${_cwd}/.tmp/consul-client.pem
export CONSUL_CLIENT_KEY=${_cwd}/.tmp/consul-client-key.pem
export CONSUL_HTTP_ADDR=http://lb.${DNS_ZONE}:8500
if [[ -f ${_cwd}/.tmp/consul.txt ]]; then
  export CONSUL_HTTP_TOKEN=$(< ${_cwd}/.tmp/consul.txt)
fi

retry \
  "consul members" \
  "Checking for Consul Mebers list"

consul acl policy create -name 'anonymous-pol' -description "Anonymous Token Policy" -rules @${mypath}/anonymous-acl.hcl
consul acl token update -id 00000000-0000-0000-0000-000000000002 -policy-name anonymous-pol -description "Anonymous Token Policy"

export VAULT_ADDR=https://lb.${DNS_ZONE}:8200
export VAULT_CACERT=${_cwd}/.tmp/sandbox-ca.pem

retry \
  "vstatus=$(curl -skI -o /dev/null -w "%{http_code}" $VAULT_ADDR/v1/sys/health)" \
  "Checking Vault status"

retry \
  "vault operator init -key-shares=1 -key-threshold=1 -recovery-shares=1 -recovery-threshold=1 -format=json > .tmp/vault.json" \
  "Initializing Vault"

log "INFO" "Completed HashiStack initialization"