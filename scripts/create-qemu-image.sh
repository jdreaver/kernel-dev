#!/usr/bin/env bash

set -euxo pipefail

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
    image_path=$images_dir/debian.img
    sudo rm -f $image_path
    qemu-img create "$image_path" 10G

    # Associate the image with a loop device and enable partition scanning (-P)
    loop_device=$(sudo losetup --show -fP "$image_path")

    mount_dir=images/deb-image-mount
    sudo rm -rf "$mount_dir"
    mkdir $mount_dir

    # Function to clean up loop device on exit
    cleanup() {
        sudo umount -R "$mount_dir" || true
        sudo losetup -d "$loop_device" || true
        sudo rm -rf "$mount_dir"
    }
    trap cleanup EXIT

    # Create a GPT partition table
    sudo parted "$loop_device" --script -- mklabel gpt

    # Define partition sizes
    # Root partition: 80% of the disk
    # Swap partition: 20% of the disk
    sudo parted "$loop_device" --script -- mkpart primary ext4 1MiB 80%
    sudo parted "$loop_device" --script -- mkpart primary linux-swap 80% 100%

    # Inform the OS of partition table changes
    sudo partprobe "$loop_device"

    # Wait briefly to ensure the system recognizes the new partitions
    sleep 1

    # Determine partition device names
    # On many systems, partitions are named like /dev/loop0p1, /dev/loop0p2
    # Adjust accordingly based on your system's naming convention
    if [ -e "${loop_device}p1" ]; then
        root_partition="${loop_device}p1"
        swap_partition="${loop_device}p2"
    else
        # Fallback for systems without 'p' in partition names
        root_partition="${loop_device}p1"
        swap_partition="${loop_device}p2"
    fi

    # Format the root partition as ext4 and label it 'root'
    sudo mkfs.ext4 -L root "$root_partition"

    # Format the swap partition and label it 'swap'
    sudo mkswap -L swap "$swap_partition"
    sudo mount -t ext4 "$root_partition" "$mount_dir"
    if [ ! -d "$mount_dir" ]; then
        mkdir "$mount_dir"
    fi

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

    # Unmount the root partition
    sudo umount -R --detach-loop "$mount_dir"

    # Clean up
    sudo rmdir "$mount_dir"

    # Remove the loop device (probably redundant with umount --detach-loop)
    sudo losetup -d "$loop_device"
else
    echo "Unknown image_type '$image_type'"
    exit 1
fi
