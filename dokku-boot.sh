#!/bin/bash

set -eo pipefail

ME="$(readlink -f "$0")"
MD="$(dirname "$ME")"
SD="$MD/$(basename "$ME" .sh).d"

[ -r "$MD/env.sh" ] && . "$MD/env.sh"

find "$SD" -type f -executable \
   | LC_ALL=C sort             \
   | while read S ; do
      "$S"
   done
