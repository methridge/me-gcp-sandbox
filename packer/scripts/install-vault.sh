#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

sudo rm -rf /tmp/terraform-google-vault

if [ "${VAULT_VERSION}" == "" ]; then
  export VAULT_VERSION=$(curl --silent \
    "https://api.github.com/repos/hashicorp/vault/tags?per_page=1" \
    | jq '.[0].name' -r \
    | sed 's/^.//')
fi

if [[ "${VAULT_VERSION}" == *"-beta"* ]]; then
  if [[ "${VAULT_VERSION_EXTRA}" != "" ]]; then
    export VAULT_VERSION="${VAULT_VERSION/-/$VAULT_VERSION_EXTRA-}"
    export VAULT_VERSION_EXTRA=""
  fi
fi

git -c advice.detachedHead=false clone --branch $(curl --silent \
  "https://api.github.com/repos/hashicorp/terraform-google-vault/tags?per_page=1" \
  | jq '.[0].name' -r) \
  https://github.com/hashicorp/terraform-google-vault.git \
  /tmp/terraform-google-vault

/tmp/terraform-google-vault/modules/install-vault/install-vault \
  --version ${VAULT_VERSION}${VAULT_VERSION_EXTRA}

if [ "${VAULT_PREMIUM}" = "true" ]; then
  echo "Installing Premium Version"
  /snap/bin/gsutil cp gs://sandbox-bin/vault/${VAULT_VERSION}/vault-enterprise_${VAULT_VERSION}+prem_linux_amd64.zip /tmp/vault.zip
  unzip -d /tmp /tmp/vault.zip
  sudo mv /tmp/vault /opt/vault/bin/vault
  sudo chown vault:vault /opt/vault/bin/vault
  sudo chmod a+x /opt/vault/bin/vault
  sudo setcap cap_ipc_lock=+ep $(readlink -f $(which vault))
fi