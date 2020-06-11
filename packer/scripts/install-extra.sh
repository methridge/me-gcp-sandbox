#!/bin/bash
# set -euxo pipefail
set -e

# Get versions of additional tools
if [ "${CONSUL_TEMPLATE_VERSION}" == "" ]; then
  export CONSUL_TEMPLATE_VERSION=$(curl -sSL \
    https://releases.hashicorp.com/index.json \
    | jq -r '."consul-template".versions | keys | .[]' \
    | sort --version-sort | tail -n1)
fi

if [ "${ENVCONSUL_VERSION}" == "" ]; then
  export ENVCONSUL_VERSION=$(curl -sSL \
    https://releases.hashicorp.com/index.json \
    | jq -r '.envconsul.versions | keys | .[]' \
    | sort --version-sort | tail -n1)
fi

if [ "${TERRAFORM_VERSION}" == "" ]; then
  export TERRAFORM_VERSION=$(curl -sSL \
    https://releases.hashicorp.com/index.json \
    | jq -r '.terraform.versions | keys | .[]' \
    | grep -v 'alpha\|beta\|rc\|oci' \
    | sort --version-sort | tail -n1)
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

