#!/bin/bash
set -eo pipefail
apt-get -y update || { sleep 5 && apt-get -y update ; }
apt-get -y upgrade
