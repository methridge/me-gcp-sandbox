#!/bin/bash
# set -euxo pipefail
set -e

export DEBIAN_FRONTEND=noninteractive

sudo apt-get --quiet --assume-yes install resolvconf

# Setup resolv to use DNSMasq for consul
sudo mkdir --parents /etc/resolvconf/resolv.conf/
sudo touch /etc/resolvconf/resolv.conf/head
echo 'nameserver 127.0.0.1' | sudo tee -a /etc/resolvconf/resolv.conf/head
echo 'nameserver 127.0.0.53' | sudo tee -a /etc/resolvconf/resolv.conf/head
sudo systemctl start resolvconf.service
sudo systemctl enable resolvconf.service

# Get versions of additional tools
if [ "${CONSUL_TEMPLATE_VERSION}" == "" ]; then
  export CONSUL_TEMPLATE_VERSION=$(curl --silent \
    "https://api.github.com/repos/hashicorp/consul-template/tags?per_page=1" \
    | jq '.[0].name' -r \
    | sed 's/^.//')
fi

if [ "${ENVCONSUL_VERSION}" == "" ]; then
  export ENVCONSUL_VERSION=$(curl --silent \
    "https://api.github.com/repos/hashicorp/envconsul/tags?per_page=1" \
    | jq '.[0].name' -r \
    | sed 's/^.//')
fi

if [ "${TERRAFORM_VERSION}" == "" ]; then
  export TERRAFORM_VERSION=$(curl --silent \
    "https://api.github.com/repos/hashicorp/terraform/tags?per_page=1" \
    | jq '.[0].name' -r \
    | sed 's/^.//')
fi

# Download additional binaries
curl --silent --output /tmp/consul-template.zip https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip
curl --silent --output /tmp/envconsul.zip https://releases.hashicorp.com/envconsul/${ENVCONSUL_VERSION}/envconsul_${ENVCONSUL_VERSION}_linux_amd64.zip
curl --silent --output /tmp/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Unzip downloaded binaries
unzip -qq -d /tmp /tmp/consul-template.zip
unzip -qq -d /tmp /tmp/envconsul.zip
unzip -qq -d /tmp /tmp/terraform.zip

# Change ownership of downloaded binaries
sudo chown root:root /tmp/consul-template /tmp/envconsul /tmp/terraform

# Move binaries to /usr/local/bin/
sudo mv /tmp/consul-template /tmp/envconsul /tmp/terraform /usr/local/bin/

sudo mv /tmp/files/ca.pem /opt/vault/tls/ca.crt.pem
sudo mv /tmp/files/vault.pem /opt/vault/tls/vault.crt.pem
sudo mv /tmp/files/vault-key.pem /opt/vault/tls/vault.key.pem
sudo /tmp/terraform-google-vault/modules/update-certificate-store/update-certificate-store --cert-file-path /opt/vault/tls/ca.crt.pem
sudo mv /tmp/files/run-consul.sh /opt/consul/bin/run-consul
sudo mv /tmp/files/run-nomad.sh /opt/nomad/bin/run-nomad
sudo mv /tmp/files/run-vault.sh /opt/vault/bin/run-vault
sudo chown consul:consul /opt/consul/bin/run-consul
sudo chown nomad:nomad /opt/nomad/bin/run-nomad
sudo chown vault:vault /opt/vault/bin/run-vault
sudo chown -R vault:vault /opt/vault/tls
sudo chmod 755 /opt/consul/bin/run-consul
sudo chmod 755 /opt/nomad/bin/run-nomad
sudo chmod 755 /opt/vault/bin/run-vault
