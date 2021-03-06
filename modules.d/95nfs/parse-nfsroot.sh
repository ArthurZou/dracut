#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# Preferred format:
#       root=nfs[4]:[server:]path[:options]
#
# This syntax can come from DHCP root-path as well.
#
# Legacy format:
#       root=/dev/nfs nfsroot=[server:]path[,options]
#
# In Legacy root=/dev/nfs mode, if the 'nfsroot' parameter is not given
# on the command line or is empty, the dhcp root-path is used as
# [server:]path[:options] or the default "/tftpboot/%s" will be used.
#
# If server is unspecified it will be pulled from one of the following
# sources, in order:
#       static ip= option on kernel command line
#       DHCP next-server option
#       DHCP server-id option
#       DHCP root-path option
#
# NFSv4 is only used if explicitly requested with nfs4: prefix, otherwise
# NFSv3 is used.
#

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

#Don't continue if root is ok
[ -n "$rootok" ] && return

# This script is sourced, so root should be set. But let's be paranoid
[ -z "$root" ] && root=$(getarg root=)
[ -z "$netroot" ] && netroot=$(getarg netroot=)
[ -z "$nfsroot" ] && nfsroot=$(getarg nfsroot=)

# netroot= cmdline argument must be ignored, but must be used if
# we're inside netroot to parse dhcp root-path
if [ -n "$netroot" ] ; then
    if [ "$netroot" = "$(getarg netroot=)" ] ; then
        warn "Ignoring netroot argument for NFS"
        netroot=$root
    fi
else
    netroot=$root;
fi

# LEGACY: nfsroot= is valid only if root=/dev/nfs
if [ -n "$nfsroot" ] ; then
    # @deprecated
    warn "Argument nfsroot is deprecated and might be removed in a future release. See 'man dracut.kernel' for more information."
    if [ "$(getarg root=)" != "/dev/nfs"  ]; then
        die "Argument nfsroot only accepted for legacy root=/dev/nfs"
    fi
    netroot=nfs:$nfsroot;
fi

case "$netroot" in
    /dev/nfs) netroot=nfs;;
    /dev/*) unset netroot; return;;
    # LEGACY: root=<server-ip>:/<path
    [0-9]*:/*|[0-9]*\.[0-9]*\.[0-9]*[!:]|/*)
        netroot=nfs:$netroot;;
esac

# Continue if nfs
case "${netroot%%:*}" in
    nfs|nfs4|/dev/nfs);;
    *) unset netroot; return;;
esac

# Check required arguments

if nfsdomain=$(getarg rd.nfs.domain rd_NFS_DOMAIN); then
    if [ -f /etc/idmapd.conf ]; then
        sed -i -e \
            "s/^[[:space:]#]*Domain[[:space:]]*=.*/Domain = $nfsdomain/g" \
            /etc/idmapd.conf
    fi
    # and even again after the sed, in case it was not yet specified
    echo "Domain = $nfsdomain" >> /etc/idmapd.conf
fi

nfsroot_to_var $netroot
[ "$path" = "error" ] && die "Argument nfsroot must contain a valid path!"

# Set fstype, might help somewhere
fstype=${nfs#/dev/}

# NFS actually supported? Some more uglyness here: nfs3 or nfs4 might not
# be in the module...
if ! incol2 /proc/filesystems $fstype ; then
    modprobe nfs
    incol2 /proc/filesystems $fstype || die "nfsroot type $fstype requested but kernel/initrd does not support nfs"
fi

# Rewrite root so we don't have to parse this uglyness later on again
netroot="$fstype:$server:$path:$options"

# If we don't have a server, we need dhcp
if [ -z "$server" ] ; then
    DHCPORSERVER="1"
fi;

# Done, all good!
rootok=1

# Shut up init error check or make sure that block parser wont get
# confused by having /dev/nfs[4]
root="$fstype"

echo '[ -e $NEWROOT/proc ]' > $hookdir/initqueue/finished/nfsroot.sh
