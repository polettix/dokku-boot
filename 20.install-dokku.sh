#!/bin/bash

: ${DOKKU_TAG:='v0.7.2'}
export DOKKU_TAG

wget https://raw.githubusercontent.com/dokku/dokku/"$DOKKU_TAG"/bootstrap.sh
bash bootstrap.sh
