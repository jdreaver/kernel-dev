#!/usr/bin/env bash

set -eu

if [ $# -lt 2 ]; then
    echo 'Usage: run-qemu-kernel.sh <linux-dir> <qemu-image> [shared-directory]'
    exit 1
fi

linux_dir=$1
qemu_image=$2

qemu_disks=(-hda "$qemu_image")

# Create ancillary disk from shared-directory
if [ $# -eq 3 ]; then
    shared_directory=$3

    shared_image=shared-disk.img
    rm -f "$shared_image"
    qemu-img create "$shared_image" 5G
    mkfs.ext4 "$shared_image"

    mount_dir=/tmp/qemu-shared-mount
    rm -rf "$mount_dir"
    mkdir "$mount_dir"

    sudo mount -o loop "$shared_image" "$mount_dir"
    sudo rsync -avh "$shared_directory" "$mount_dir"
    sudo umount -R "$mount_dir"
    sudo rm -rf "$mount_dir"

    qemu_disks+=(-hdb "$shared_image")
fi

qemu-system-x86_64 \
    -kernel "$linux_dir/arch/x86/boot/bzImage" \
    "${qemu_disks[@]}" \
    -append "root=/dev/sda console=ttyS0" \
    -enable-kvm \
    -nographic
