#!/usr/bin/env bash

set -euxo pipefail

# Fail if not run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Remove old version of module if it exists
if lsmod | grep -q "mydebugfs"; then
    rmmod mydebugfs
    sleep 1 # Give it a sec to get removed
fi

# Insert module
insmod mydebugfs.ko

# Test it out
mydebugfs_root=/sys/kernel/debug/mydebugfs

ls -lah "$mydebugfs_root"

# mybool
cat "$mydebugfs_root/mybool"
echo true > "$mydebugfs_root/mybool"
cat "$mydebugfs_root/mybool"
echo 0 > "$mydebugfs_root/mybool"
cat "$mydebugfs_root/mybool"

# mycounter
cat "$mydebugfs_root/mycounter"
cat "$mydebugfs_root/mycounter"
echo 5 > "$mydebugfs_root/mycounter"
cat "$mydebugfs_root/mycounter"
echo 0 > "$mydebugfs_root/mycounter"
cat "$mydebugfs_root/mycounter"
cat "$mydebugfs_root/mycounter"

# simple_counter
cat "$mydebugfs_root/simple_counter"
cat "$mydebugfs_root/simple_counter"
echo 5 > "$mydebugfs_root/simple_counter"
cat "$mydebugfs_root/simple_counter"
echo 0 > "$mydebugfs_root/simple_counter"
cat "$mydebugfs_root/simple_counter"
cat "$mydebugfs_root/simple_counter"
