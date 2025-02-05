#!/usr/bin/env bash

set -uo pipefail

rg --files-with-matches '#define debugfs_node dentry' | while read -r file; do
    echo "Fixing $file"

    # Replace this:
    #   struct dentry;
    #   #define debugfs_node dentry
    # with this:
    #   struct dentry;
    sed -i 's/struct dentry;/struct debugfs_node;/g' "$file"
    sed -i '/#define debugfs_node dentry/d' "$file"
done
