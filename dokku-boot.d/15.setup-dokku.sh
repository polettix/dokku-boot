#!/bin/bash

set -eo pipefail

set_selection() {
   printf '%s' "dokku dokku/$1 $2 $3" | debconf-set-selections
}

set_unattended() {
   local DOMAIN="$1"

   # set unattended
   set_selection web_config boolean false

   # ensure key file is in place and is considered
   local KEYFILE=/root/.ssh/id_rsa.pub
   head -1 /root/.ssh/authorized_keys >"$KEYFILE"
   set_selection skip_key_file boolean false
   set_selection key_file      string  "$KEYFILE"

   # if a domain is provided, use it and turn on vhost mode
   if [ -n "DOMAIN" ] ; then
      set_selection vhost_enable boolean true
      set_selection hostname     string  "$DOMAIN"
   fi

   return 0
}

case "$UNATTENDED" in
   (y*|Y*|1)
      set_unattended "$DOMAIN"
      ;;
esac
