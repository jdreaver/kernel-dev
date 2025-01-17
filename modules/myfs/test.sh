#!/usr/bin/env bash

set -euxo pipefail

# Fail if not run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Remove old version of module if it exists
if lsmod | grep -q "myfs"; then
    rmmod myfs
    sleep 3 # Give it a sec to get removed
fi

# Insert module
insmod myfs.ko

# Ensure filesystem exists
grep myfs /proc/filesystems

# Recreate mount point
mount_point=/mnt/myfs
umount -f "$mount_point" || true
rm -rf "$mount_point"
mkdir -p "$mount_point"

# Mount filesystem
mount -t myfs myfs "$mount_point"

# Test filesystem
echo "Hello, world!" > "$mount_point/hello.txt"
cat "$mount_point/hello.txt"
ls -lah "$mount_point"
