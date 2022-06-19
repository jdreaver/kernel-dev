#!/usr/bin/env bash

# Downloads a source tarball for a given Linux kernel version and extracts it to
# this directory.
#
# Protip: look for versions at:
# - https://www.kernel.org/
# - https://mirrors.edge.kernel.org/pub/linux/kernel/

if [ $# -ne 1 ]; then
    echo 'Usage: fetch-kernel-version.sh <version>'
    exit 1
fi

version=$1

# TODO: Ensure directory doesn't already exist
dir_name="linux-${version}"
if [ -d "$dir_name" ]; then
    echo "Directory $dir_name already exists. Refusing to overwrite."
    exit 1
fi

# Extract major version because of CDN URL structure
major_version="${version::1}"

tar_file="${dir_name}.tar.xz"
wget "https://cdn.kernel.org/pub/linux/kernel/v${major_version}.x/${tar_file}"
tar xvf "$tar_file"
rm "$tar_file"

echo "Extracting /proc/config.gz to $dir_name/.config"
gunzip < /proc/config.gz > "$dir_name/.config"
