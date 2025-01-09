#!/usr/bin/env bash

set -eu

if [ $# -ne 1 ]; then
    echo 'Usage: create-qemu-image.sh <image-type>'
    exit 1
fi

image_type=$1
images_dir=images

if [ "$image_type" = "nixos" ]; then

    pushd flake/
    nix build .#qemu-image
    popd
    mkdir -p images
    install -m 644 flake/result/nixos.img images/
    rm flake/result

elif [ "$image_type" = "debian" ]; then

  # Inspired by https://nixos.wiki/wiki/Kernel_Debugging_with_QEMU#Create_a_bootable_NixOS_image_with_no_kernel
  image_path=$images_dir/debian.img
  qemu-img create "$image_path" 5G
  mkfs.ext4 "$image_path"

  mount_dir=images/deb-image-mount
  if [ ! -d "$mount_dir" ]; then
      mkdir "$mount_dir"
  fi

  sudo mount -o loop "$image_path" "$mount_dir"
  sudo debootstrap --arch amd64 buster "$mount_dir"
  sudo chroot "$mount_dir" /bin/bash -i -c "
  set -eu
  # Don't require root password
  /usr/bin/passwd -d root

  # Auto-login to serial console as root
  /bin/mkdir -p /etc/systemd/system/serial-getty@ttyS0.service.d/
  /bin/cat > /etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --keep-baud 115200,38400,9600 %I $TERM
EOF

  exit
  "
  sudo umount -R "$mount_dir"

else
    echo "Unknown image_type '$image_type'"
    exit 1
fi
