#!/usr/bin/env bash

# Compile the kernel with "KBUILD_CFLAGS += -save-temps=obj" added to
# the Makefile so we spit out .i files. This script will then search
# those files to ensure we #include <linux/debugfs.h> before using
# struct debugfs_node.

set -uo pipefail

rg --files-with-matches 'struct debugfs_node' -g '*.h' | while read -r file; do
    debugfs_line=$(rg -n 'struct debugfs_node' "$file" | head -n1 | cut -d: -f1)
    # debugfs_line=$(rg -n '\s+.*struct debugfs_node.*,' "$file" | head -n1 | cut -d: -f1)
    include_or_def=$(rg -n '#include <linux/debugfs.h>|struct debugfs_node;|#define debugfs_node dentry' "$file" | head -n1 | cut -d: -f1)

    if [[ -n "$debugfs_line" && ( -z "$include_or_def" || "$debugfs_line" -lt "$include_or_def" ) ]]; then
        echo "$file"
    fi
done
