#!/usr/bin/env bash

set -eu

if [ $# -ne 1 ]; then
    echo 'Usage: create-qemu-image.sh <image-type>'
    exit 1
fi

image_type=$1

if [ "$image_type" = "nixos" ]; then

    pushd flake/
    nix build .#qemu-image
    popd
    install -m 644 flake/result/nixos.img .
    rm flake/result

elif [ "$image_type" = "debian" ]; then

  # Inspired by https://nixos.wiki/wiki/Kernel_Debugging_with_QEMU#Create_a_bootable_NixOS_image_with_no_kernel
  image_name=debian.img
  qemu-img create "$image_name" 5G
  mkfs.ext4 "$image_name"

  mount_dir=deb-image-mount
  if [ ! -d "$mount_dir" ]; then
      mkdir "$mount_dir"
  fi

  sudo mount -o loop "$image_name" "$mount_dir"
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

else
    echo "Unknown image_type '$image_type'"
    exit 1
fi
