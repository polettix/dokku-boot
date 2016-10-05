#!/bin/bash

set -eo pipefail

ME="$(readlink -f "$0")"
BME="$(basename "$ME")"
MD="$(dirname "$ME")"

cd "$MD"
for script in $(ls *sh | LC_ALL=C sort) ; do
   [ -f "$script" -a -x "$script" ] || continue
   [ "$script" = "$BME" ] && continue
   "$MD/$script"
done
