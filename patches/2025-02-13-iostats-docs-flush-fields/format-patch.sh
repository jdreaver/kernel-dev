#!/usr/bin/env bash

set -euo pipefail

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
patch_dir="$script_dir/v1-patch"

rm -rf "$patch_dir"

git format-patch master...HEAD \
    --base=origin/master \
    -o "$patch_dir/" \
    --in-reply-to '0e8c8ead-423a-45f3-9e10-020334ef8907@infradead.org' \
    --to 'Jonathan Corbet <corbet@lwn.net>' \
    --to 'Randy Dunlap <rdunlap@infradead.org>' \
    --cc 'Jens Axboe <axboe@kernel.dk>' \
    --cc 'Konstantin Khlebnikov <koct9i@gmail.com>' \
    --cc 'linux-doc@vger.kernel.org' \
    --cc 'linux-block@vger.kernel.org' \
    --cc 'linux-kernel@vger.kernel.org' \
    --cc 'David Reaver <me@davidreaver.com>'

"$script_dir/../../scripts/add-patch-comments.sh" "$patch_dir"/*.patch "$script_dir/patch-comments.txt"
