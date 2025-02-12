#!/usr/bin/env bash

set -euo pipefail

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
patch_dir="$script_dir/v1-patches"

rm -rf "$patch_dir"

git format-patch master...HEAD \
    --base=origin/master \
    -o "$patch_dir/" \
    --to 'Andrew Morton <akpm@linux-foundation.org>' \
    --to 'Greg Kroah-Hartman <gregkh@linuxfoundation.org>' \
    --cc 'Jens Axboe <axboe@kernel.dk>' \
    --cc 'Alexander Viro <viro@zeniv.linux.org.uk>' \
    --cc 'Jani Nikula <jani.nikula@intel.com>' \
    --cc 'Christoph Hellwig <hch@lst.de>' \
    --cc 'linux-block@vger.kernel.org' \
    --cc 'linux-trace-kernel@vger.kernel.org' \
    --cc 'linux-kernel@vger.kernel.org' \
    --cc 'David Reaver <me@davidreaver.com>'

"$script_dir/../../scripts/add-patch-comments.sh" "$patch_dir"/*.patch "$script_dir/patch-comments.txt"
