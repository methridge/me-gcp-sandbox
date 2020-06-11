#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

if [ "${VAULT_VERSION}" == "" ]; then
  export VAULT_VERSION=$(curl -sSL https://releases.hashicorp.com/index.json \
    | jq -r ".vault.versions | keys | .[]" \
    | grep -v 'oci\|ent' | sort --version-sort | tail -n1)
fi

if [ "${VAULT_PREMIUM}" = "true" ]; then
  echo "Installing Premium Version"
  /snap/bin/gsutil cp \
  gs://sandbox-bin/vault/${VAULT_VERSION}/vault-enterprise_${VAULT_VERSION}+prem_linux_amd64.zip \
  /tmp/vault.zip
else
  echo "Installing Releases Version"
  curl --silent --output /tmp/vault.zip \
  https://releases.hashicorp.com/vault/${VAULT_VERSION}${VAULT_VERSION_EXTRA}/vault_${VAULT_VERSION}${VAULT_VERSION_EXTRA}_linux_amd64.zip
fi

unzip -d /tmp /tmp/vault.zip
sudo mv /tmp/vault /usr/local/bin/vault
sudo chown root:root /usr/local/bin/vault
sudo chmod a+x /usr/local/bin/vault
sudo setcap cap_ipc_lock=+ep /usr/local/bin/vault

sudo useradd --system --home /etc/vault.d --shell /bin/false vault

sudo mv /tmp/files/vault.service /etc/systemd/system/vault.service
sudo chown root:root /etc/systemd/system/vault.service
sudo chmod 755 /etc/systemd/system/vault.service

sudo mkdir --parents /etc/vault.d/tls
sudo mkdir --parents /opt/vault/data

sudo mv /tmp/files/ca.pem /etc/vault.d/tls/ca.crt.pem
sudo mv /tmp/files/vault.pem /etc/vault.d/tls/vault.crt.pem
sudo mv /tmp/files/vault-key.pem /etc/vault.d/tls/vault.key.pem
sudo mv /tmp/files/run-vault.sh /usr/local/bin/run-vault
sudo chown root:root /usr/local/bin/run-vault
sudo chown -R vault:vault /etc/vault.d /opt/vault
sudo chmod 755 /usr/local/bin/run-vault

# Add Vault CA
sudo cp /etc/vault.d/tls/ca.crt.pem /usr/local/share/ca-certificates/custom.crt
sudo update-ca-certificates