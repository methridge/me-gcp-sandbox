#!/bin/zsh -x
# Vault Init Script

vstatus=$(curl -skI -o /dev/null -w "%{http_code}" $VAULT_ADDR/v1/sys/health)

while true; do
  if [[ "$vstatus" -eq 501 ]]; then
    echo "Initializing Vault"
    vault operator init -recovery-shares=1 -recovery-threshold=1 -format=json > cluster-keys.json
    direnv reload
    sleep 10
    vault write sys/license text=$(cat "/Volumes/GoogleDrive/My Drive/licenses/vault.hclic")
    break
  elif [[ "$vstatus" -eq 200 ]]; then
    echo "Vault Active"
  elif [[ "$vstatus" -eq 429 ]]; then
    echo "Vault Standby"
  elif [[ "$vstatus" -eq 472 ]]; then
    echo "Vault DR node"
  elif [[ "$vstatus" -eq 473 ]]; then
    echo "Vault PerfStandby"
  elif [[ "$vstatus" -eq 503 ]]; then
    echo "Vault Sealed"
  else
    echo "Unknown status"
  fi
done