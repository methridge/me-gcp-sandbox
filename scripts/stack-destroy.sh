#!/bin/zsh
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
log "INFO" "Resetting environment"
sudo cp /etc/hosts.orig /etc/hosts
: > .tmp/consul.json
: > .tmp/nomad.txt
: > .tmp/vault.json
direnv reload
reset-ssh