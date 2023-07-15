#!/usr/bin/env bash

# This script generates some custom buildroot files for my raspberry pi that are
# derived from files in the main buildroot source tree. There is no easy way to
# patch these files declaratively, so I copy them here and modify them.

set -eu

# defconfig
defconfig_file="configs/reaver_rpi_defconfig"
printf "# THIS FILE IS AUTOGENERATED! See generate-files.sh\n\n" > "$defconfig_file"

cat ../buildroot/configs/raspberrypi4_64_defconfig >> "$defconfig_file"

# shellcheck disable=SC2016
sed -i 's|BR2_PACKAGE_RPI_FIRMWARE_CONFIG_FILE="board/raspberrypi4-64/config_4_64bit.txt"|BR2_PACKAGE_RPI_FIRMWARE_CONFIG_FILE="$(BR2_EXTERNAL_REAVER_RPI_PATH)/board/reaver/rpi/config.txt"|' "$defconfig_file"

cat <<'EOF' >> "$defconfig_file"

# Custom stuff starts here
BR2_PACKAGE_DROPBEAR=y

BR2_ROOTFS_OVERLAY="$(BR2_EXTERNAL_REAVER_RPI_PATH)/board/reaver/rpi/overlay/"
EOF

# config.txt
config_txt_file="board/reaver/rpi/config.txt"
printf "# THIS FILE IS AUTOGENERATED! See generate-files.sh\n\n" > "$config_txt_file"
cat ../buildroot/board/raspberrypi/config_4_64bit.txt >> "$config_txt_file"

# Enable i2c buses
cat <<'EOF' >> "$config_txt_file"

# Custom stuff starts here
dtparam=i2c_arm=on
dtparam=i2c1=on
EOF