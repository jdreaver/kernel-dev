#!/usr/bin/env bash

set -eu

# Inspired by https://nixos.wiki/wiki/Kernel_Debugging_with_QEMU#Create_a_bootable_NixOS_image_with_no_kernel
qemu-img create qemu-image.img 5G
mkfs.ext2 qemu-image.img

mount_dir=deb-image-mount
if [ ! -d "$mount_dir" ]; then
    mkdir "$mount_dir"
fi

sudo mount -o loop qemu-image.img "$mount_dir"
sudo debootstrap --arch amd64 buster "$mount_dir"
sudo chroot "$mount_dir" /bin/bash -i -c "
set -eu
# Don't require root password
/usr/bin/passwd -d root
exit
"
sudo umount -R "$mount_dir"

# Arch wiki says this will auto login to serial console, but it seems to just
# hang when I add it to the image.
# /bin/mkdir -p /etc/systemd/system/serial-getty@ttyS0.service.d/
# /bin/cat << EOF > /etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf
# [Service]
# ExecStart=
# ExecStart=-/sbin/agetty -o '-p -f -- \\u' --keep-baud --autologin root 115200,57600,38400,9600 - $TERM
# EOF
