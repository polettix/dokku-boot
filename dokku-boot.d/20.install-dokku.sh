#!/bin/bash

id dokku >/dev/null 2>&1 && exit 0

if [ -z "$DOKKU_TAG" ] ; then
   DOKKU_TAG="$(
      curl https://raw.githubusercontent.com/dokku/dokku/master/README.md \
      | sed -n 's#wget https://.*/dokku/\(v.*\)/bootstrap.sh#\1#p'
   )"
fi

export DOKKU_TAG
wget https://raw.githubusercontent.com/dokku/dokku/"$DOKKU_TAG"/bootstrap.sh
bash bootstrap.sh
