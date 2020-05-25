#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

sudo apt-get --quiet --assume-yes update
sudo apt-get --quiet --assume-yes upgrade
sudo apt-get --quiet --assume-yes dist-upgrade
sudo apt-get --quiet --assume-yes autoremove
sudo apt-get --quiet --assume-yes install curl unzip jq
