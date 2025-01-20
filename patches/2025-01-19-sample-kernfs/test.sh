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

# Test root directory counters
cat "$mount_point/counter"
cat "$mount_point/counter"
cat "$mount_point/counter"

# Test a subdirectory
mkdir "$mount_point/sub1"
cat "$mount_point/sub1/counter"
cat "$mount_point/sub1/counter"
cat "$mount_point/sub1/counter"

# TODO (once we have rmdir implemented): Recreate sub1 and counters should reset
rmdir "$mount_point/sub1"
mkdir "$mount_point/sub1"
cat "$mount_point/sub1/counter"
cat "$mount_point/sub1/counter"
cat "$mount_point/sub1/counter"
