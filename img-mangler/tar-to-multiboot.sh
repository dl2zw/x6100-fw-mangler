#!/bin/sh -e
# (C) 2026 DL2ZW, GPLv2 see LICENSE
#
# turn an unpacked sdcard image (output of img-to-tar.sh) into a tarball,
# that can be extracted onto partition 2 of an existing multiboot sdcard
#
# usage: tar-to-multiboot.sh <image.tar> <out.tar.gz> <name>
#
# * rootfs from part2, boot files (zImage, *.dtb) from part1 into /boot
# * multiboot-vanillafy.sh: remove S01create_data, comment out mmcblk0p3 /mnt
# * result contains one directory <name>/

PS4='> ${0##*/}: '
#set -x

IN="${1:?E: input tar missing}"
OUT="${2:?E: output tarball missing}"
NAME="${3:?E: name missing}"
HERE="${0%/*}"

case "$NAME" in
  */* | .* | Default | Button[0-9] )
    echo "E: '$NAME' is no valid directory name for the multiboot sdcard" >&2
    exit 1
    ;;
esac

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT HUP INT TERM

echo "I: unpack $IN"
  mkdir "$WORK/img"
  tar xf "$IN" --numeric-owner -C "$WORK/img"

if [ ! -d "$WORK/img/part2/etc" ]; then
  echo "E: $IN has no rootfs in part2/, layout is:" >&2
  ls "$WORK/img" >&2
  [ ! -f "$WORK/img/part3/rootfs.tar" ] || \
    echo "E: looks like a Xiegu update image, use xiegu-vanilla instead" >&2
  exit 1
fi

ROOT="$WORK/out/$NAME"
mkdir -p "$WORK/out"
mv "$WORK/img/part2" "$ROOT"

if [ -d "$WORK/img/part1" ]; then
  echo "I: copy part1 to /boot"
  mkdir -p "$ROOT/boot"
  cp -a "$WORK/img/part1/." "$ROOT/boot/"
fi

# u-boot loads /<name>/boot/zImage and /<name>/boot/${fdtfile}
[ -f "$ROOT/boot/zImage" ] || \
  echo "W: $NAME: no /boot/zImage, u-boot can not boot it" >&2
ls "$ROOT"/boot/*.dtb > /dev/null 2>&1 || \
  echo "W: $NAME: no /boot/*.dtb, u-boot can not boot it" >&2

sh -e "$HERE/multiboot-vanillafy.sh" "$ROOT"

echo "I: pack $OUT"
  tar czf "$OUT" --numeric-owner --xattrs --acls -C "$WORK/out" "$NAME"

[ -z "$OWNER" ] || \
  chown "$OWNER${GROUP:+:$GROUP}" "$OUT"

echo "I: done, copy to the sdcard (partition 2, as root):"
echo "I:   tar xzf ${OUT##*/} --numeric-owner -C <mountpoint>"
echo "I:   ln -sfn $NAME <mountpoint>/Button3"
