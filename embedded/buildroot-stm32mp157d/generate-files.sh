#!/usr/bin/env bash

# This script generates some custom buildroot files for my STM32MP157d that are
# derived from files in the main buildroot source tree. There is no easy way to
# patch these files declaratively, so I copy them here and modify them.

set -eu

# overlay
cp -r ../buildroot/board/stmicroelectronics/stm32mp157a-dk1/overlay board/reaver/stm32mp157d/

defconfig_file="configs/reaver_stm32mp157d_defconfig"
printf "# THIS FILE IS AUTOGENERATED! See generate-files.sh\n\n" > "$defconfig_file"

cat ../buildroot/configs/stm32mp157a_dk1_defconfig >> "$defconfig_file"

cat <<EOF >> "$defconfig_file"

# Custom stuff starts here
BR2_SYSTEM_DHCP="end0"

BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES="\$(BR2_EXTERNAL_REAVER_STM32MP157D_PATH)/board/reaver/stm32mp157d/kernel.fragment"

BR2_PACKAGE_DROPBEAR=y
BR2_PACKAGE_NANO=y

BR2_ROOTFS_OVERLAY="\$(BR2_EXTERNAL_REAVER_STM32MP157D_PATH)/board/reaver/stm32mp157d/overlay/"

BR2_TARGET_GENERIC_HOSTNAME="reaver-stm32"

# External toolchain to speed things up
BR2_TOOLCHAIN_EXTERNAL=y
BR2_TOOLCHAIN_EXTERNAL_ARM_ARM=y

# Use bash
BR2_SYSTEM_BIN_SH_BASH=y

# Use systemd
BR2_INIT_SYSTEMD=y
BR2_PACKAGE_SYSTEMD_ANALYZE=y
EOF
