#!/bin/bash
dracut_install mount mknod mkdir modprobe pidof sleep chroot echo sed sh ls
# install our scripts and hooks
inst "$initfile" "/init"
inst "$switchroot" "/sbin/switch_root"
inst_hook pre-pivot 50 "$dsrc/hooks/selinux-loadpolicy.sh"
inst_hook pre-mount 99 "$dsrc/hooks/resume.sh"
