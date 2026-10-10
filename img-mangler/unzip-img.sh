#!/bin/sh
# (C) 2023 Joerg Jungermann, GPLv2 see LICENSE
# (C) 2026 DL2ZW
set -e

IN="$1"
OUT="$2"

# pick the image from the zip:
# * $ZIP_IMG if set (make ... ZIP_IMG=name.img)
# * the only .img in the zip
# * the .img named like the output file
IMGS="$(unzip -Z1 "$IN" | grep -E '[.]img$' || :)"
COUNT="$(echo "$IMGS" | grep -c . || :)"

if [ -n "$ZIP_IMG" ]; then
  IMG="$ZIP_IMG"
elif [ "$COUNT" = 1 ]; then
  IMG="$IMGS"
else
  IMG="$(echo "$IMGS" | grep -xF "${OUT##*/}" || :)"
fi

if [ -z "$IMG" ] || ! echo "$IMGS" | grep -qxF "$IMG"; then
  echo "E: $IN: can not choose an image${IMG:+, '$IMG' not found}. Images in zip:" >&2
  echo "$IMGS" | sed 's/^/E:   /' >&2
  echo "E: choose one with: make $OUT ZIP_IMG=<name>" >&2
  exit 1
fi

echo "I: $IN: extract $IMG"
unzip -p "$IN" "$IMG" > "$OUT"

[ -z "$OWNER" ] || \
  chown "$OWNER${GROUP:+:$GROUP}" "$OUT"
