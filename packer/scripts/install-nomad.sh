#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

if [ "${NOMAD_VERSION}" == "" ]; then
  export NOMAD_VERSION=$(curl -sSL https://releases.hashicorp.com/index.json \
    | jq -r ".nomad.versions | keys | .[]" | sort --version-sort | tail -n1)
fi

if [ "${NOMAD_PREMIUM}" = "true" ]; then
  echo "Installing Premium Version"
  /snap/bin/gsutil cp \
  gs://sandbox-bin/nomad/${NOMAD_VERSION}/nomad-enterprise_${NOMAD_VERSION}+ent_linux_amd64.zip \
  /tmp/nomad.zip
else
  echo "Installing Releases Version"
  curl --silent --output /tmp/nomad.zip \
  https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}${NOMAD_VERSION_EXTRA}_linux_amd64.zip
fi

unzip -d /tmp /tmp/nomad.zip
sudo mv /tmp/nomad /usr/local/bin/nomad
sudo chown root:root /usr/local/bin/nomad
sudo chmod a+x /usr/local/bin/nomad

sudo mkdir --parents /opt/nomad

sudo mv /tmp/files/nomad.service /etc/systemd/system/nomad.service
sudo chown root:root /etc/systemd/system/nomad.service
sudo chmod 755 /etc/systemd/system/nomad.service

sudo mkdir --parents /etc/nomad.d

sudo mv /tmp/files/run-nomad.sh /usr/local/bin/run-nomad
sudo chmod 755 /usr/local/bin/run-nomad
