#!/bin/bash

set -e

sudo mkdir -p /opt/gruntwork
sudo rm -rf /tmp/bash-commons

git -c advice.detachedHead=false clone --branch $(curl --silent \
  "https://api.github.com/repos/gruntwork-io/bash-commons/tags?per_page=1" \
  | jq '.[0].name' -r) \
  https://github.com/gruntwork-io/bash-commons.git \
  /tmp/bash-commons

sudo cp -r /tmp/bash-commons/modules/bash-commons/src /opt/gruntwork/bash-commons
