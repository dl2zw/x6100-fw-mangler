#!/bin/sh -e
# (C) 2023 Joerg Jungermann, GPLv2 see LICENSE
# (C) 2026 DL2ZW

PS4='> ${0##*/}: '
#set -x

# keep the original /dev of the firmware for multiboot-vanilla, outside of /target
mkdir -p /target/dev
tar cf /orig-dev.tar -C /target dev

# chroot steps need device nodes like /dev/null
tar cf - -C / dev | tar xf - -C /target
