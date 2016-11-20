#!/bin/bash

set -eo pipefail

ME="$(readlink -f "$0")"
MD="$(dirname "$ME")"
SD="$MD/$(basename "$ME" .sh).d"

echo >&2 -e "\nOLD_PWD[$OLD_PWD]\n"
[ -r "$OLD_PWD/env.sh" ] && . "$OLD_PWD/env.sh"

find "$SD" -type f -executable \
   | LC_ALL=C sort             \
   | while read S ; do
      "$S"
   done
