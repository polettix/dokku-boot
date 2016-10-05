#!/bin/bash

id dokku >/dev/null 2>&1 && exit 0

: ${DOKKU_TAG:='v0.7.2'}
export DOKKU_TAG

wget https://raw.githubusercontent.com/dokku/dokku/"$DOKKU_TAG"/bootstrap.sh
bash bootstrap.sh
