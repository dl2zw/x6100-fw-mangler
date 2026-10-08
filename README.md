# X6100 image mangler

 It takes X6100 flashable firmware images and creates a modified image or MMC bootable images via Docker.
 It uses qemu-user-static if needed to run code for foreign architectures.

## Motivation
 * make playing around with this device easier
 * easy integrating modifications
 * make modifications reproducible
 * ease debugging

## Features
 * generates a runable SDCard image with some modifications with an new partition layout
 * generates a runable update image on SDCard with some modifications with a new partition layout
 * integrates some more helper utils from Alpine into stock images

## `Don't`s
 No warranty, I will not be responsible for what ever you do with these generated images.
 They might break your device,it might eletrocute you, be warned. Act safe and sane.
 Only transmit in frequency ranges you are allowed to transmit, check for a clean HF of your device.
 I advise not distributing images generated this way, they contain copyrighted material.

# Quickstart

 * Install the software on your system listed in the Requirements section below.
 * copy `./config.example` to `./config`
 * edit `config` with your favorite editor
 * comment out the images you want to experiment with, I suggest starting with the `sdcard` images.
 * save the file and exit editor
 * type `make`

# Requirements
 * Install [docker](https://www.docker.com/)
 * `qemu-user-static` with a proper `binfmt` config, although if not available un your platform there is a small helper in the tools section.

## OSX
 Rancher Desktop or Docker Desktop fulfill this requirements.
 Homebrew might be handy.
 With Rancher Desktop you might need to execute the script `bin/binfmt-helper` before it works.

## Ubuntu/Debian
 * Docker, ideally Community edition
 * `build-essentials`, `make`
 * `qemu-user-binfmt`, to execute armhf binaries in case you are on aarch64, x86_64, ...
 * ...

# Usage

## Docker

 General usage

 * `make url` - Downloads all SDCard and update images
 * `make` - generates all Docker images
 * `make clean` - cleans up the directory

### Images
   
 * `xiegu-vanilla` - Xiegu orignal
 * `r1cbu-vanilla` - alternative of R1CBU/R2RFE
 * `k4vz-r1cbu-vanilla` - alternative of R1CBU/R2RFE with added rade_demod_wav and newer buildroot from fventuri
 * `xiegu-modded` - Xiegu orignal patched, add more userland tools to rootfs
 * `r1cbu-modded` - alternative of R1CBU/R2RFE, rootfs extended
 * `multiboot-vanilla` - boots per default vanilla, If you keep the left-most-button pressed until you see a changed boot logo of the R1CBU/R2RFE firmware to boot it.
 * `multiboot-modded` - boots per default modded, If you keep the left-most-button pressed until you see a changed boot logo of the R1CBU/R2RFE firmware to boot it.
 
 You can boot the different Images from sdcard by pressing and holding one of the 5 buttons below the display.The button on the far right is Button 1, the button on the far left is Button 5.
 * `Button 1` - alternative of R1CBU/R2RFE
 * `Button 2` - alternative of R1CBU/R2RFE with added rade_demod_wav and newer buildroot from fventuri
 * `Button 3` - Xiegu orignal (free for other Images)
 * `Button 4` - Xiegu orignal (free for other Images)
 * `Button 5` - Xiegu orignal (free for other Images)
 * `No Button` - Xiegu orignal
 
#### Login via ssh
 * User: root
 * Password: x6100

#### tl:dr Workflow

 * Archiv -> Image -> TarDump -> Dockerimage --> ... modding --> desired state of /target in image
 * Dockerimage `Name` --> `name.sdcard.img`
 * Dockerimage `Name` --> `name.update.img`

 eg.
 * `make xiegu-modded.sdcard.img` - generates a modded image of the original Xiegu Firmware
 * `make r1cbu-modded.sdcard.img` - the same for the R1CBU/R2RFE OpenSource firmware

 * `make modded.update.img` - generates a update image for installing it into the devies's eMMC
 * `make r1cbu-modded.update.img` - the same for the R1CBU/R2RFE OpenSource firmware

 * `make multiboot-modded.sdcard.img` - this is an image with latest Xiegu and R1CBU/R2RFE Firmware in one.
 * `make multiboot-modded.update.img` - the same but for writing on the eMMC

#### Patches

 The modded Xiegu image includes this patches:
 * added a bluetoothd startup script from https://github.com/strijar/x6100_bt_patch, to allow easier pairing from the command line
 * patch https://github.com/busysteve/X6100-Bluetooth-Audio
 * disable automounting of random USB or MMC hotplug devices for now
 * enable bash as standard shell
 * add serial console helpers to copy with different sized terminal emulator, no more 80x24 if your terminal app behaves

### `./config` and `./config.example`
 `./config` is a preseed for different settings:
 * which images to build and
 * what config to include into into the images.
 It is not tracked by git.

 `./config.examle` is a small example with some comments.

### Under the hood

 The make file creates at first a docker image x6100:img-mangler with needed tools.
 Afterwards the sources from the .url files are downloaded and extracted.
 The resulting update images from Xiegu or R1BCU are then copied into the contents of /target of a docker image for later modifications.
 The modified contents then could be used to generate update images or images to be run from sdcard.
 With binfmt under Linux with docker you can even enter the Image as it would run on the x6100, of course without a GUI.

### Debugging

 `make V=1`

# Tools

 A short description about the tools in ./bin

 If you have a running envrc setup, you can use the .envrc to  have ./bin included in your PATH.

 * `D6100` - enter the mangling docker container with the source tree mounted in /src
 * `buildroot` - enter container with prepared buildroot environment
 * `binfmt-helper` - this install qemu-user-static and some binfmt signatures to enable running arm code on your workstation for development

## You have a fresh unknown image and wants to inspect its contents?

 * copy it to unknown-beauty.img into this directory
 * type `make unknown-beauty.tar`

 This depacks the image to the tar file `unknown-beauty.tar` for easier use.

# General X6100 help

## WiFi

How to connect to a WiFi via the serial console:
``` sh
nmcli device wifi con WLANNAME password XXXXXXXXX
```

The X6100 is found to have issues with WPA3 personal (SAE) in some environments. This can be disabled to fallback to WPA2 only:
```
nmcli conn down WLANNAME
nmcli conn edit WLANNAME << EOF
  set wifi-sec.key-mgmt wpa-psk
EOF
nmcli conn up WLANNAME
```

## Overall boot process

 * CPU boots up one core
 * loads internal bootloader BROM https://linux-sunxi.org/BROM
 * look for a EGON signature 4k after device start https://linux-sunxi.org/EGON first on SD card slot, and then at the eMMC
 * if found an EGON signature, it is loading the binary in our case U-Boot
 * U-Boot is searching for a MBR style partition table, especially it searches for _bootable_ partition where it tries to execute a `uboot.scr` to be executed
 * `uboot.scr` contains the code to load kernel, a DTB and maybe an initrd file and boots it

 The uboot used in Xiegus image oder R1CBU/R2RFE is able to detect where it has been booted from. The UBoot environment contains a variable `devnum` set to
 * 0 if booted from the SD card slot
 * 1 if booted from the internal eMMC

 That way it is sufficent to dump the first ca 640k of the update or use the official UBoot image from `/usr/share/emmc_sources/u-boot-sunxi-with-spl.bin` as bootloader
 for images build.

 Q: the siuze for the UBoot is not yet exactly known, but could be determined by the EGON header. (TODO)

## Frequency extension / MARS mod

Xiegu's official firmware can be configured to enable TX on all frequencies and bands, also those not be in the HAM bands.
It is unknown if the filter circuits in the device itself are taking harm, so this is a modification on your own risk.

The file `/etc/xgradio/xgradio.conf` needs to be edited. In case of the version 1.1.7 firmware it looks like this:
```
[mods]
fullband-tx=disable
```
If you edit this with you favorite editor, you can chose for the `fullband-tx` setting
 * `disable` - factory default - only TX on HAM bands
 * `enable` - enable TX on all frequencies the TRX supports.

Restart the TRX (or just the radio app) afterwards.

## Boot counter since official Xiegu 1.1.7

Since 1.1.7 the radio app of Xiegu stores the number of starts in `/etc/xgradio/man.conf`
The `exec-counter` is incremented on every start of the radio app.

```
[root@x6100:~]# cat /etc/xgradio/man.conf
[manufacture]
exec-counter=23
```


