#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

sudo rm -rf /tmp/terraform-google-consul

if [ "${CONSUL_VERSION}" == "" ]; then
  export CONSUL_VERSION=$(curl --silent \
    "https://api.github.com/repos/hashicorp/consul/tags?per_page=1" \
    | jq '.[0].name' -r \
    | sed 's/^.//')
fi

if [[ "${CONSUL_VERSION}" == *"-beta"* ]]; then
  if [[ "${CONSUL_VERSION_EXTRA}" != "" ]]; then
    export CONSUL_VERSION="${CONSUL_VERSION/-/$CONSUL_VERSION_EXTRA-}"
    export CONSUL_VERSION_EXTRA=""
  fi
fi

git -c advice.detachedHead=false clone --branch $(curl --silent \
  "https://api.github.com/repos/hashicorp/terraform-google-consul/tags?per_page=1" \
  | jq '.[0].name' -r) \
  https://github.com/hashicorp/terraform-google-consul.git \
  /tmp/terraform-google-consul

/tmp/terraform-google-consul/modules/install-consul/install-consul \
  --version ${CONSUL_VERSION}${CONSUL_VERSION_EXTRA}

/tmp/terraform-google-consul/modules/install-dnsmasq/install-dnsmasq

if [ "${CONSUL_PREMIUM}" = "true" ]; then
  echo "Installing Premium Version"
  /snap/bin/gsutil cp gs://sandbox-bin/consul/${CONSUL_VERSION}/consul-enterprise_${CONSUL_VERSION}+prem_linux_amd64.zip /tmp/consul.zip
  unzip -d /tmp /tmp/consul.zip
  sudo mv /tmp/consul /opt/consul/bin/consul
  sudo chown consul:consul /opt/consul/bin/consul
  sudo chmod a+x /opt/consul/bin/consul
fi
