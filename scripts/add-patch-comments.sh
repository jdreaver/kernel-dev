#!/usr/bin/env bash

# Adds the contents of the given comments file to the given patch file,
# after the first occurrence of --- in the patch file.

set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <patch_file> <comments_file>"
    exit 1
fi

patch_file=$1
comments_file=$2
tmp_file=$(mktemp)
trap 'rm -f $tmp_file' 0 2 3 15 # Nuke the tmp file on exit

found=0
while IFS= read -r line; do
    echo "$line" >> "$tmp_file"
    if [[ "$found" -eq 0 && "$line" == ---* ]]; then
        echo '' >> "$tmp_file"
        cat "$comments_file" >> "$tmp_file"
        echo '' >> "$tmp_file"
        found=1
    fi
done < "$patch_file"

mv "$tmp_file" "$patch_file"
rm -f "$tmp_file"
