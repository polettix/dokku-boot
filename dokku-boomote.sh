#!/bin/bash

main() {
   set -eo pipefail

   set_environment "$@"

   if [ -z "$DOKKU_IP" ] ; then
      DOKKU_IP="$(instantiate_vm)"
   fi

   CREDENTIALS="root@$DOKKU_IP"
   wait_vm_up

   set_DNS

   remote_operations

   echo "*.$DOKKU_HOSTNAME => $DOKKU_IP"
}

set_environment() {
   ME="$(readlink -f "$0")"
   MD="$(dirname "$ME")"

   DOKKU_HOSTNAME="${1:-"$DOKKU_HOSTNAME"}"
   : ${DOKKU_VHOST_ENABLE:='true'}
   : ${DOKKU_WEB_CONFIG:='false'}
   : ${DOKKU_KEY_FILE:='/root/.ssh/authorized_keys'}
   DOKKU_IP="$2"

   if [ -e 'env.sh' ] ; then
      . 'env.sh'
   fi

   if [ -z "$DOKKU_HOSTNAME" ] ; then
      echo >&2 "no domain, set DOKKU_HOSTNAME or pass a domain name"
      return 1
   fi

   return 0
}

instantiate_vm() {
   echo >&2 "instantiating VM via $VM_PROVIDER"
   local RVAL="$(DOMAIN="$DOKKU_HOSTNAME" "$MD/new-vm.d/$VM_PROVIDER.sh")"
   if [ -n "$RVAL" ] ; then
      echo "$RVAL"
      return 0
   fi

   echo >&2 "cannot get an IP to connect to"
   return 1
}

wait_vm_up() {
   for SLEEP_TIME in 0 1 2 3 4 5 ; do
      sleep "$SLEEP_TIME"
      ssh >/dev/null 2>&1 \
            -o ConnectTimeout="$((SLEEP_TIME + 1))" \
            -o UserKnownHostsFile=/dev/null \
            -o StrictHostKeyChecking=no \
            "$CREDENTIALS" ls / \
         && return 0
   done

   echo "cannot SSH to $DOKKU_IP"
   return 1
}

set_DNS() {
   if [ -z "$DNS_PROVIDER" ] ; then
      echo >&2 "no DNS_PROVIDER, skipping DNS setting"
      return 0
   fi

   echo "setting *.$DOKKU_HOSTNAME to $DOKKU_IP via $DNS_PROVIDER"
   "$MD/dns.d/$DNS_PROVIDER.sh" \
         set-wildcard-address "$DOKKU_HOSTNAME" "$DOKKU_IP" \
      && return 0
   echo "cannot set DNS"
   return 1
}

remote_operations() {
   local NH='-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
   (
      echo "export DOKKU_VHOST_ENABLE='$DOKKU_VHOST_ENABLE'"
      echo "export DOKKU_WEB_CONFIG='$DOKKU_WEB_CONFIG'"
      echo "export DOKKU_KEY_FILE='$DOKKU_KEY_FILE'"
      echo "export DOKKU_HOSTNAME='$DOKKU_HOSTNAME'"
   ) | ssh $NH "$CREDENTIALS" tee /root/env.sh
   scp $NH "$MD/dokku-boot.pl" "$CREDENTIALS:/root/dokku-boot.pl"
   ssh $NH "$CREDENTIALS" perl "/root/dokku-boot.pl"
}

main "$@" >&2
