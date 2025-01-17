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

    mkdir -p images/
    shared_image=images/shared-disk.img
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

# Create another empty disk
dummy_disk=images/dummy.img
rm -f $dummy_disk
dd if=/dev/zero of=$dummy_disk bs=1M count=512

kernel_args="root=/dev/sda console=ttyS0"
if [[ $qemu_image == *"debian.img" ]]; then
    kernel_args="root=/dev/sda1 console=ttyS0 resume=LABEL=swap rw"
fi

ARGS=(
    -m 8G
    -kernel "$linux_dir/arch/x86/boot/bzImage"
    -hda "$qemu_image"
    -hdb "$dummy_disk"
    -append "$kernel_args"
    -machine q35,accel=kvm
    -enable-kvm
    -cpu host
    -nic user,hostfwd=tcp::2222-:22
    -nographic
)

# Docs on using GDB https://docs.kernel.org/dev-tools/gdb-kernel-debugging.html
#
# To debug a module:
# 1. Build the module with debug info
# 2. Load the module in the kernel with insmod
# 3. Get the module address with `grep <module-name> /proc/modules`. You should see something like:
#
#    myfs 16384 1 - Live 0xffffffffa0400000 (O)
#
# 4. Start gdb with `gdb vmlinux` (vmlinux is the kernel binary located in the root of a built kernel directory)
# 5. Connect to the QEMU instance with `target remote :1234`
# 6. Load the module debug symbols in GDB with `add-symbol-file <module.ko> <module-address>`. Example:
#
#    add-symbol-file myfs.ko 0xffffffffa0400000
#
# 5. Set breakpoints in your module code
# 6. Continue execution with `c`
if [ -n "${GDB:-}" ]; then
    ARGS+=(-gdb tcp::1234)
fi

exec qemu-system-x86_64 "${ARGS[@]}"
