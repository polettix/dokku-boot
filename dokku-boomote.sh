#!/bin/bash
set -eo pipefail

ME="$(readlink -f "$0")"
MD="$(dirname "$ME")"
PROGRAM="dokku-boot.pl"
export DOMAIN="$1"
DOKKU_IP="$2"

if [ -e 'env.sh' ] ; then
   . 'env.sh'
fi

if [ -z "$DOMAIN" ] ; then
   echo >&2 "no domain provided"
   exit 1
fi
export DOKKU_HOSTNAME="$DOMAIN"

if [ -z "$DOKKU_IP" ] ; then
   echo >&2 "instantiating VM via $VM_PROVIDER"
   DOKKU_IP="$("$MD/new-vm.d/$VM_PROVIDER.sh")"
fi

if [ -z "$DOKKU_IP" ] ; then
   echo >&2 "cannot get an IP to connect to"
   exit 1
fi

CREDENTIALS="root@$DOKKU_IP"
AVAILABLE=''
for SLEEP_TIME in 0 1 2 3 4 5 ; do
   sleep "$SLEEP_TIME"
   ssh >/dev/null 2>&1 \
      -o ConnectTimeout="$((SLEEP_TIME + 1))" \
      -o UserKnownHostsFile=/dev/null \
      -o StrictHostKeyChecking=no \
      "$CREDENTIALS" ls / && AVAILABLE=yes
   [ -n "$AVAILABLE" ] && break
done

if [ -z "$AVAILABLE" ] ; then
   echo >&2 "cannot SSH to $DOKKU_IP"
   exit 1
fi

echo >&2 "setting *.$DOMAIN to $DOKKU_IP via $DNS_PROVIDER"
if ! "$MD/dns.d/$DNS_PROVIDER.sh" set-wildcard-address "$DOMAIN" "$DOKKU_IP" ; then
   echo >&2 "cannot set DNS"
   exit 1
fi

(
   echo "export DOKKU_VHOST_ENABLE='$DOKKU_VHOST_ENABLE'"
   echo "export DOKKU_WEB_CONFIG='$DOKKU_WEB_CONFIG'"
   echo "export DOKKU_KEY_FILE='$DOKKU_KEY_FILE'"
   echo "export DOKKU_HOSTNAME='$DOKKU_HOSTNAME'"
) > 'remote-env.sh'

scp \
   -o UserKnownHostsFile=/dev/null \
   -o StrictHostKeyChecking=no \
   "remote-env.sh" "$CREDENTIALS:/root/env.sh"
scp \
   -o UserKnownHostsFile=/dev/null \
   -o StrictHostKeyChecking=no \
   "$MD/$PROGRAM" "$CREDENTIALS:/root/$PROGRAM"
ssh \
   -o UserKnownHostsFile=/dev/null \
   -o StrictHostKeyChecking=no \
   "$CREDENTIALS" perl "/root/$PROGRAM"

echo >&2 "*.$DOMAIN => $DOKKU_IP"
