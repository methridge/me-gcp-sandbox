#!/bin/zsh
readonly consul_lic_file="/Volumes/GoogleDrive/My Drive/licenses/consul.hclic"
readonly nomad_lic_file="/Volumes/GoogleDrive/My Drive/licenses/nomad.hclic"
readonly vault_lic_file="/Volumes/GoogleDrive/My Drive/licenses/vault.hclic"
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

export CONSUL_CACERT=.tmp/sandbox-ca.pem
export CONSUL_CLIENT_CERT=.tmp/consul-client.pem
export CONSUL_CLIENT_KEY=.tmp/consul-client-key.pem
export CONSUL_HTTP_ADDR=http://lb.${DNS_ZONE}:8500
if [[ -f .tmp/consul.txt ]]; then
  export CONSUL_HTTP_TOKEN=$(< .tmp/consul.txt)
fi

log "INFO" "Checking for Consul Mebers list"
consul members > /dev/null
while [[ $? -ne 0 ]]; do
  sleep 5
  log "INFO" "Checking for Consul Mebers list"
  consul members > /dev/null
done

export VAULT_ADDR=https://lb.${DNS_ZONE}:8200
export VAULT_CACERT=.tmp/sandbox-ca.pem

log "INFO" "Checking Vault status"
vstatus=$(curl -skI -o /dev/null -w "%{http_code}" $VAULT_ADDR/v1/sys/health)
while [[ "$vstatus" -ne 501 ]]; do
  sleep 5
  log "INFO" "Checking Vault status"
  vstatus=$(curl -skI -o /dev/null -w "%{http_code}" $VAULT_ADDR/v1/sys/health)
done

log "INFO" "Initializing Vault"
vault operator init \
  -key-shares=1 \
  -key-threshold=1 \
  -recovery-shares=1 \
  -recovery-threshold=1 \
  -format=json > .tmp/vault.json

while [[ $? -ne 0 ]]; do
  sleep 5
  log "INFO" "Initializing Vault"
  vault operator init \
    -key-shares=1 \
    -key-threshold=1 \
    -recovery-shares=1 \
    -recovery-threshold=1 \
    -format=json > .tmp/vault.json
done

export VAULT_TOKEN=$(cat .tmp/vault.json | jq -r ".root_token")

log "INFO" "Licensing Consul"
consul license put $(cat ${consul_lic_file}) > /dev/null
while [[ $? -ne 0 ]]; do
  sleep 5
  log "INFO" "Licensing Consul"
  consul license put $(cat ${consul_lic_file}) > /dev/null
done

export NOMAD_ADDR=http://lb.${DNS_ZONE}:4646
export NOMAD_TOKEN=$(sed -n 2,2p .tmp/nomad.txt | cut -d '=' -f 2 | sed 's/ //')

log "INFO" "Licensing Nomad"
nomad license put ${nomad_lic_file} > /dev/null
while [[ $? -ne 0 ]]; do
  sleep 5
  log "INFO" "Licensing Nomad"
  nomad license put ${nomad_lic_file} > /dev/null
done

log "INFO" "Licensing Vault"
vault write sys/license text=$(cat ${vault_lic_file}) > /dev/null
while [[ $? -ne 0 ]]; do
  sleep 5
  log "INFO" "Licensing Vault"
  vault write sys/license text=$(cat ${vault_lic_file}) > /dev/null
done

log "INFO" "Completed HashiStack initialization"