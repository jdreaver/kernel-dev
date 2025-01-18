#!/usr/bin/env bash

set -euxo pipefail

# Fail if not run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Remove old mount point if it exists
mount_point=/mnt/mydebugfs
umount -f "$mount_point" || true
rm -rf "$mount_point"

# Remove old version of module if it exists
if lsmod | grep -q "mydebugfs"; then
    rmmod mydebugfs
    sleep 3 # Give it a sec to get removed
fi

# Insert module
insmod mydebugfs.ko
