#!/bin/bash
# FIXME: would be nice if we didn't have to know which rules to grab....
# ultimately, /lib/initramfs/rules.d or somesuch which includes links/copies
# of the rules we want so that we just copy those in would be best
mkdir -p "$initdir/lib/udev/rules.d"
dracut_install udevd udevadm /lib/udev/*_id /lib/udev/console_*
inst_rules /lib/udev/rules.d/10-console* /lib/udev/rules.d/40-redhat* \
    /lib/udev/rules.d/50* /lib/udev/rules.d/60-persistent-storage.rules \
    /lib/udev/rules.d/61*edd* /lib/udev/rules.d/64* /lib/udev/rules.d/80* \
    /lib/udev/rules.d/95*