#!/usr/bin/env bash

set -eu

if [ $# -ne 1 ]; then
    echo 'Usage: run-qemu-kernel.sh <linux-dir>'
    exit 1
fi

linux_dir=$1

qemu-system-x86_64 -s \
    -kernel "$linux_dir/arch/x86/boot/bzImage" \
    -hda qemu-image.img \
    -append "root=/dev/sda console=ttyS0" \
    -enable-kvm \
    -nographic
