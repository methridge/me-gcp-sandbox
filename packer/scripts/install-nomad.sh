#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

sudo rm -rf /tmp/terraform-google-nomad

if [ "${NOMAD_VERSION}" == "" ]; then
  export NOMAD_VERSION=$(curl --silent \
    "https://api.github.com/repos/hashicorp/nomad/tags?per_page=1" \
    | jq '.[0].name' -r \
    | sed 's/^.//')
fi

if [[ "${NOMAD_VERSION}" == *"-beta"* ]]; then
  if [[ "${NOMAD_VERSION_EXTRA}" != "" ]]; then
    export NOMAD_VERSION="${NOMAD_VERSION/-/$NOMAD_VERSION_EXTRA-}"
    export NOMAD_VERSION_EXTRA=""
  fi
fi

git -c advice.detachedHead=false clone --branch $(curl --silent \
  "https://api.github.com/repos/hashicorp/terraform-google-nomad/tags?per_page=1" \
  | jq '.[0].name' -r) \
  https://github.com/hashicorp/terraform-google-nomad.git \
  /tmp/terraform-google-nomad

/tmp/terraform-google-nomad/modules/install-nomad/install-nomad \
  --version ${NOMAD_VERSION}${NOMAD_VERSION_EXTRA}

if [ "${NOMAD_PREMIUM}" = "true" ]; then
  echo "Installing Premium Version"
  /snap/bin/gsutil cp gs://sandbox-bin/nomad/${NOMAD_VERSION}/nomad-enterprise_${NOMAD_VERSION}+ent_linux_amd64.zip /tmp/nomad.zip
  unzip -d /tmp /tmp/nomad.zip
  sudo mv /tmp/nomad /opt/nomad/bin/nomad
  sudo chown nomad:nomad /opt/nomad/bin/nomad
  sudo chmod a+x /opt/nomad/bin/nomad
fi
