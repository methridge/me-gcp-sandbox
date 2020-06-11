#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

if [ "${CONSUL_VERSION}" == "" ]; then
  export CONSUL_VERSION=$(curl -sSL https://releases.hashicorp.com/index.json \
    | jq -r ".consul.versions | keys | .[]" | sort --version-sort | tail -n1)
fi

if [[ "${CONSUL_VERSION}" == *"-beta"* ]]; then
  if [[ "${CONSUL_VERSION_EXTRA}" != "" ]]; then
    export CONSUL_VERSION="${CONSUL_VERSION/-/$CONSUL_VERSION_EXTRA-}"
    export CONSUL_VERSION_EXTRA=""
  fi
fi

if [ "${CONSUL_PREMIUM}" = "true" ]; then
  echo "Installing Premium Version"
  /snap/bin/gsutil cp \
  gs://sandbox-bin/consul/${CONSUL_VERSION}/consul-enterprise_${CONSUL_VERSION}+prem_linux_amd64.zip \
  /tmp/consul.zip
else
  echo "Installing Releases Version"
  curl --silent --output /tmp/consul.zip \
  https://releases.hashicorp.com/consul/${CONSUL_VERSION}${CONSUL_VERSION_EXTRA}/consul_${CONSUL_VERSION}${CONSUL_VERSION_EXTRA}_linux_amd64.zip
fi


unzip -d /tmp /tmp/consul.zip
sudo mv /tmp/consul /usr/local/bin/consul
sudo chown root:root /usr/local/bin/consul
sudo chmod a+x /usr/local/bin/consul

sudo useradd --system --home /etc/consul.d --shell /bin/false consul
sudo mkdir --parents /opt/consul/data
sudo chown --recursive consul:consul /opt/consul

sudo mv /tmp/files/consul.service /etc/systemd/system/consul.service
sudo chown root:root /etc/systemd/system/consul.service
sudo chmod 755 /etc/systemd/system/consul.service

sudo mkdir --parents /etc/consul.d

sudo mv /tmp/files/run-consul.sh /usr/local/bin/run-consul
sudo chmod 755 /usr/local/bin/run-consul

# Install dnsmasq and resolvconf
sudo apt-get --quiet --assume-yes install dnsmasq resolvconf

# Configure dnsmasq
sudo mkdir --parents /etc/dnsmasq.d
sudo mv /tmp/files/10-consul /etc/dnsmasq.d/10-consul

# Setup resolv to use dnsmasq for consul
sudo mkdir --parents /etc/resolvconf/resolv.conf/
sudo mv /tmp/files/head /etc/resolvconf/resolv.conf/head
sudo systemctl enable resolvconf
sudo systemctl start resolvconf
