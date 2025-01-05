#!/usr/bin/env bash

set -euxo pipefail

if [ $# -lt 2 ]; then
    echo 'Usage: run-qemu-kernel.sh <linux-dir> <qemu-image> [shared-directory]'
    exit 1
fi

linux_dir=$1
qemu_image=$2

# Create new disk with shared dir packed in
if [ $# -eq 3 ]; then
    shared_directory=$3

    shared_image=shared-disk.img
    rm -f "$shared_image"
    cp "$qemu_image" "$shared_image"

    mount_dir=/tmp/qemu-shared-mount
    rm -rf "$mount_dir"
    mkdir "$mount_dir"

    sudo mount -o loop "$shared_image" "$mount_dir"
    share_dest="$mount_dir/shared"
    sudo mkdir "$share_dest"
    sudo rsync -avh "$shared_directory" "$share_dest"
    sudo umount -R "$mount_dir"
    sudo rm -rf "$mount_dir"

    qemu_image="$shared_image"
fi

qemu-system-x86_64 \
    -m 8G \
    -kernel "$linux_dir/arch/x86/boot/bzImage" \
    -hda "$qemu_image" \
    -append "root=/dev/sda console=ttyS0" \
    -machine q35,accel=kvm \
    -enable-kvm \
    -cpu host \
    -nographic
