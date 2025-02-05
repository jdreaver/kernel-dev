#!/usr/bin/env bash

set -euo pipefail

# Store bash script source directory
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

log_dir=/tmp/cocci-logs
rm -rf "$log_dir"
mkdir -p "$log_dir"

# Use ripgrep to find any files that contain debugfs-looking code. This
# is a simple heuristic to avoid running spatch on files that don't
# contain debugfs code.
files=$(rg --files-with-matches 'debugfs|dentry' -g '*.{c,h}' -g '!fs/debugfs' -g '!include/linux/debugfs.h' -g '!include/linux/fs.h' | sort)

counter=1
total_files=$(echo "$files" | wc -l)
for file in $files; do
    echo "($counter/$total_files) $file"
    counter=$((counter+1))

    time spatch "$script_dir/script.cocci" \
      --all-includes --include-headers --patch . \
      --ignore include/linux/fs.h \
      --ignore include/linux/debugfs.h \
      --ignore fs/debugfs \
      --in-place "$file" 2>&1 \
      | tee "$log_dir/$(echo "$file" | tr '/' '--').log"
done

# Undo the changes to some files. Some of these should not be modified,
# and some are handled in the later manual fixup commit.
git checkout -- \
  drivers/s390/block/dasd.c \
  fs/bcachefs/xattr.h \
  fs/btrfs/export.h \
  fs/btrfs/ioctl.h \
  fs/btrfs/transaction.h \
  fs/btrfs/tree-log.h \
  fs/debugfs \
  fs/ntfs3/ntfs_fs.h \
  fs/udf/udfdecl.h \
  include/drm/ttm/ttm_resource.h \
  include/linux/capability.h \
  include/linux/debugfs.h \
  include/linux/exportfs.h \
  include/linux/file.h \
  include/linux/fs.h \
  include/linux/fs_context.h \
  include/linux/irqdesc.h \
  include/linux/kernfs.h \
  include/linux/mount.h \
  include/linux/path.h \
  include/linux/security.h \
  include/linux/statfs.h
