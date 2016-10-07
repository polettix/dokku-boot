#!/bin/bash

# create swap file only if really necessary
FREE_MEMORY=$(grep MemTotal /proc/meminfo | awk '{print $2}')
[ "$FREE_MEMORY" -lt 1003600 ] || exit 0

# avoid creating it over and over
IMG='/var/swap.img'
[ -e "$IMG" ] && exit 0

# do the thing
touch "$IMG"
chmod 600 "$IMG"
dd if=/dev/zero of="$IMG" bs=1024k count=1000
mkswap "$IMG"
swapon "$IMG"
