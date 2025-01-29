#!/usr/bin/env bash

set -euxo pipefail

cd ~/git/kernel-dev/linux

# Apply patch to all of these subdirs
dirs=(
    arch/powerpc
    arch/s390
    arch/x86
    block
    drivers/acpi
    drivers/base
    drivers/bus
    drivers/char
    drivers/dma
    drivers/gpu
    drivers/misc
    drivers/phy
    drivers/pinctrl
    lib
    mm
    net/wireless
    sound/core
    sound/drivers
    virt/kvm
)

for dir in "${dirs[@]}"; do
    time make coccicheck COCCI=/home/david/git/kernel-dev/patches/2025-01-28-debugfs-opaque-handle/structured.cocci MODE=patch M="$dir" > patch.patch
    # There will be errors because for some reason coccinelle will add header
    # files multiple times in the patch. Ignore errors.
    patch --force -p1 -i patch.patch || true
done
