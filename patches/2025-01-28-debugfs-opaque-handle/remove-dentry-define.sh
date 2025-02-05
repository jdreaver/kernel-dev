#!/usr/bin/env bash

set -uo pipefail

rg --files-with-matches '#define debugfs_node dentry' | while read -r file; do
    echo "Fixing $file"
    sed -i 's/#define debugfs_node dentry/struct debugfs_node;/g' "$file"
done
