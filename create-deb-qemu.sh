#!/usr/bin/env bash

set -eu

# Inspired by https://nixos.wiki/wiki/Kernel_Debugging_with_QEMU#Create_a_bootable_NixOS_image_with_no_kernel
qemu-img create qemu-image.img 5G
mkfs.ext2 qemu-image.img
mkdir mount-point.dir
sudo mount -o loop qemu-image.img mount-point.dir
sudo debootstrap --arch amd64 buster mount-point.dir
# sudo chroot mount-point.dir /bin/bash -i
# export PATH=$PATH:/bin
# passwd # Set root password
# exit
sudo umount -R mount-point.dir
