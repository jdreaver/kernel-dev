#!/usr/bin/env bash

set -euxo pipefail

if [ $# -ne 1 ]; then
    echo 'Usage: minimal-qemu-kernel-config.sh <kernel-source-dir>'
    exit 1
fi

kernel_dir=$1

cd "$kernel_dir"
make mrproper # Clears all artifacts, do this especially if you upgrade from a significant old version
make defconfig kvm_guest.config
scripts/config \
  --set-val DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT y \
  --set-val DEBUG y \
  --set-val GDB_SCRIPTS y \
  --set-val DEBUG_DRIVER y \
  --set-val CONFIG_IKCONFIG y \
  --set-val CONFIG_IKCONFIG_PROC y \
  --set-val CONFIG_LOCALVERSION '"-reaver-dev"' \
  --set-val CONFIG_LOCALVERSION_AUTO y

# Use new .config (properly merges config and allows you to inspect .config)
make oldconfig
