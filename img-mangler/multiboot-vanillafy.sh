#!/bin/sh -e
# (C) 2026 DL2ZW, GPLv2 see LICENSE
#
# undo build-only changes of a *-vanilla rootfs for the multiboot sdcard
# usage: multiboot-vanillafy.sh <rootfs-dir> [<original-dev.tar>]
#
# * remove /etc/.git and /etc/.gitignore of the vanilla build step
# * restore /dev as found in the firmware image
# * remove S01create_data, the sdcard has no data partition
# * comment out the /dev/mmcblk0p3 /mnt fstab entry for the same reason

PS4='> ${0##*/}: '
#set -x

ROOT="${1:?E: rootfs dir missing}"
DEVTAR="$2"
[ -d "$ROOT/etc" ] || { echo "E: $ROOT is no rootfs" >&2; exit 1; }

echo "I: $ROOT: remove /etc/.git"
  rm -rf "$ROOT/etc/.git" "$ROOT/etc/.gitignore"

if [ -r "$DEVTAR" ]; then
  echo "I: $ROOT: restore original /dev"
  rm -rf "$ROOT/dev"
  tar xf "$DEVTAR" -C "$ROOT"
else
  echo "W: $ROOT: no original /dev saved, keep it" >&2
fi
# multiboot init moves devtmpfs to /dev, the mount point must exist
mkdir -p "$ROOT/dev"

if [ -e "$ROOT/etc/init.d/S01create_data" ]; then
  echo "I: $ROOT: remove S01create_data"
  rm -f "$ROOT/etc/init.d/S01create_data"
fi

if [ -f "$ROOT/etc/fstab" ] && \
   grep -qE '^[[:space:]]*/dev/mmcblk0p3[[:space:]]+/mnt[[:space:]]' "$ROOT/etc/fstab"; then
  echo "I: $ROOT: fstab: comment out /dev/mmcblk0p3 /mnt"
  sed -i -E 's|^([[:space:]]*/dev/mmcblk0p3[[:space:]]+/mnt[[:space:]].*)$|#\1|' "$ROOT/etc/fstab"
fi
