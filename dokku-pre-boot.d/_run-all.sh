#!/bin/sh
set -e
ME="$(readlink -f "$0")"
MYNAME="$(basename "$ME")"
MD="$(dirname "$ME")"
cd "$MD"
for f in * ; do
   [ -x "$f" ] || continue
   [ "x$f" = "x$MYNAME" ] && continue
   "./$f"
done
