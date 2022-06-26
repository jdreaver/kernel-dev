#!/usr/bin/env bash

set -eu

if [ $# -ne 2 ]; then
    echo 'Usage: run-qemu-kernel.sh <linux-dir> <qemu-image>'
    exit 1
fi

linux_dir=$1
qemu_image=$2

qemu-system-x86_64 -s \
    -kernel "$linux_dir/arch/x86/boot/bzImage" \
    -hda "$qemu_image" \
    -append "root=/dev/sda console=ttyS0" \
    -enable-kvm \
    -nographic
