#!/usr/bin/env bash

set -euo pipefail

# Store bash script source directory
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

log_dir=/tmp/cocci-logs
rm -rf "$log_dir"
mkdir -p "$log_dir"

# Use ripgrep to find any files that contain debugfs-looking code
# This is a simple heuristic to avoid running spatch on files that don't contain debugfs code
files=$(rg --files-with-matches 'debugfs|dentry' -g '*.{c,h}' -g '!fs/debugfs' -g '!linux/include/debugfs.h' -g '!linux/include/fs.h' | sort)

counter=1
total_files=$(echo "$files" | wc -l)
for file in $files; do
    echo "($counter/$total_files) $file"
    counter=$((counter+1))

    time spatch "$script_dir/script.cocci" --all-includes --include-headers --patch . --in-place "$file" 2>&1 | tee "$log_dir/$(echo "$file" | tr '/' '--').log"
done
