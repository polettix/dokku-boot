#!/bin/bash

set -eo pipefail

ME="$(readlink -f "$0")"
MD="$(dirname "$ME")"
SD="$MD/$(basename "$ME" .sh).d"

[ -r "$OLD_PWD/env.sh" ] && . "$OLD_PWD/env.sh"

find "$SD" -type f -executable \
   | LC_ALL=C sort             \
   | while read S ; do
      printf >&2 '%s\n' "$S"
      "$S" </dev/zero
   done
