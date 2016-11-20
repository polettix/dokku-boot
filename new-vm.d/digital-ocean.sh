#!/bin/bash
set -eo pipefail

main() {
   fix_variables
   local DROPLET_ID="$(droplet_create)"
   local DROPLET DROPLET_STATUS
   for x in 40 5 5 5 5 10 10 20 30 60 ; do
      echo >&2 "sleeping $x seconds, please be patient..."
      sleep "$x"
      DROPLET="$(droplet_data "$DROPLET_ID")"
      DROPLET_STATUS="$(echo "$DROPLET" | teepee -v 'droplet.status')"
      [ "$DROPLET_STATUS" == 'active' ] && break
   done
   if [ "$DROPLET_STATUS" != 'active' ] ; then
      echo >&2 "sorry, droplet $DROPLET_ID did not become active"
      exit 1
   fi

   echo >&2 "droplet created, id is $DROPLET_ID"
   echo "$DROPLET" | teepee -nv droplet.networks.v4.0.ip_address
}

fix_variables() {
   if [ -r 'env.sh' ] ; then
      . 'env.sh'
   fi
   if [ -z "$DO_TOKEN" ] ; then
      echo >&2 "You have to set DO_TOKEN as an env variable (e.g. in env.sh)"
      exit 1
   fi
   if [ -z "$DOMAIN" ] ; then
      echo >&2 "You have to set DOMAIN as an env variable (e.g. in env.sh)"
      exit 1
   fi
   if [ -z "$DO_SSH_KEY_ID" ] ; then
      echo >&2 "You have to set DO_SSH_KEY_ID as an env variable (e.g. in env.sh)"
      exit 1
   fi
   : ${DO_IMAGE:='debian-8-x64'}
   : ${DO_REGION:='ams2'}
   : ${DO_SIZE:='512mb'}
}

droplet_data() {
   curl \
      -X GET \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $DO_TOKEN" \
      "https://api.digitalocean.com/v2/droplets/$1"
}

droplet_create() {
   local JSON="$(cat - <<END
{
   "name": "$DOMAIN",
   "region": "$DO_REGION",
   "size": "$DO_SIZE",
   "image": "$DO_IMAGE",
   "ssh_keys": ["$DO_SSH_KEY_ID"],
   "backups": false,
   "ipv6": false,
   "user_data": null,
   "private_networking": null,
   "volumes": null,
   "tags": ["dokku"]
}
END
   )"

   local RES="$(
      curl \
         -X POST \
         -H "Content-Type: application/json" \
         -H "Authorization: Bearer $DO_TOKEN" \
         -d "$JSON" \
         'https://api.digitalocean.com/v2/droplets'
   )"

   local DROPLET_ID="$(echo "$RES" | teepee -v 'droplet.id')"
   if [ -z "$DROPLET_ID" ] ; then
      echo >&2 "cannot get droplet identifier from retrieved data"
      echo "$RES" | teepee -FYAML >&2
      exit 1
   fi

   echo "$DROPLET_ID"
}

main
