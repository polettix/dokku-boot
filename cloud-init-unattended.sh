#!/bin/sh
apt-get update &&
apt-get install -y curl perl &&
curl -LO https://github.com/polettix/dokku-boot/raw/master/dokku-boot.pl &&
UNATTENDED=yes DOMAIN=example.com perl dokku-boot.pl
