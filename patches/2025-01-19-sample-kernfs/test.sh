#!/usr/bin/env bash

set -euo pipefail

# Fail if not run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Recreate mount point
mount_point=/sample_kernfs
umount -f "$mount_point" || true
rm -rf "$mount_point"
mkdir -p "$mount_point"

set -x

# Ensure filesystem exists
grep sample_kernfs /proc/filesystems

# Mount filesystem
mount -t sample_kernfs sample_kernfs "$mount_point"

# Test filesystem
cat "$mount_point/counter"
cat "$mount_point/counter"
cat "$mount_point/counter"
