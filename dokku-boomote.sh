#!/bin/bash

main() {
   set -eo pipefail

   set_environment "$@"

   [ -n "$DOKKU_IP" ] || DOKKU_IP="$(instantiate_vm)"

   CREDENTIALS="root@$DOKKU_IP"
   wait_vm_up

   set_DNS

   remote_operations

   echo "$DOKKU_WILDCARD.$DOKKU_DOMAIN => $DOKKU_IP"
}

set_environment() {
   ME="$(readlink -f "$0")"
   MD="$(dirname "$ME")"

   if [ -e 'env.sh' ] ; then
      . 'env.sh'
   fi

   # override from command line, if any
   DOKKU_DOMAIN="${1:-"$DOKKU_DOMAIN"}"

   if [ -z "$DOKKU_DOMAIN" ] ; then
      printf >&2 "please set DOKKU_DOMAIN or pass as first argument"
      return 1
   fi

   DOKKU_SUBDOMAIN="${2:-"$DOKKU_SUBDOMAIN"}"
   DOKKU_IP="${3:-"$DOKKU_IP"}"

   # set default values at last, if necessary
   if [ -n "$DOKKU_SUBDOMAIN" ] ; then
      : ${DOKKU_HOSTNAME:="$DOKKU_SUBDOMAIN.$DOKKU_DOMAIN"}
      DOKKU_WILDCARD="*.$DOKKU_SUBDOMAIN"
   else
      : ${DOKKU_HOSTNAME:="$DOKKU_DOMAIN"}
      DOKKU_WILDCARD="*"
   fi
   : ${DOKKU_KEY:="$HOME/.ssh/id_rsa"}
   : ${DOKKU_VHOST_ENABLE:='true'}
   : ${DOKKU_WEB_CONFIG:='false'}
   : ${DOKKU_KEY_FILE:='/root/.ssh/authorized_keys'}

   return 0
}

instantiate_vm() {
   echo >&2 "instantiating VM via $VM_PROVIDER"
   local RVAL="$(TARGET_HOSTNAME="$DOKKU_HOSTNAME" "$MD/new-vm.d/$VM_PROVIDER.sh")"
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
            -i "$DOKKU_KEY" \
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

   echo "setting $DOKKU_WILDCARD.$DOKKU_DOMAIN to $DOKKU_IP via $DNS_PROVIDER"
   "$MD/dns.d/$DNS_PROVIDER.sh" \
         set-wildcard-address "$DOKKU_DOMAIN" "$DOKKU_IP" "$DOKKU_WILDCARD" \
      && return 0
   echo "cannot set DNS"
   return 1
}

remote_sshish() {
   local cmd=$1
   shift
   "$cmd" \
      -o UserKnownHostsFile=/dev/null \
      -o StrictHostKeyChecking=no     \
      -i "$DOKKU_KEY" \
      "$@"
}

remote_ssh() {
   remote_sshish ssh "$CREDENTIALS" "$@"
}

remote_scp() {
   remote_sshish scp "$@"
}

pre_deploy() {
   (cd "$MD" && tar czf - dokku-pre-boot.d) \
      | remote_ssh tar xzC /root -f -
   remote_ssh /root/dokku-pre-boot.d/_run-all.sh
}

remote_operations() {
   pre_deploy

   (
      echo "export DOKKU_VHOST_ENABLE='$DOKKU_VHOST_ENABLE'"
      echo "export DOKKU_WEB_CONFIG='$DOKKU_WEB_CONFIG'"
      echo "export DOKKU_KEY_FILE='$DOKKU_KEY_FILE'"
      echo "export DOKKU_HOSTNAME='$DOKKU_HOSTNAME'"
   ) | remote_ssh tee /root/env.sh
   remote_scp "$MD/dokku-boot.pl" "$CREDENTIALS:/root/dokku-boot.pl"
   remote_ssh perl "/root/dokku-boot.pl"
}

main "$@" >&2
