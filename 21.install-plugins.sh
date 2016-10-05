#!/bin/bash

BASE='/var/lib/dokku/plugins/available'

[ -e "$BASE/letsencrypt" ] \
   || dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git
[ -e "$BASE/postgres" ] \
   || dokku plugin:install https://github.com/dokku/dokku-postgres.git postgres
[ -e "$BASE/redis" ] \
   || dokku plugin:install https://github.com/dokku/dokku-redis.git redis
