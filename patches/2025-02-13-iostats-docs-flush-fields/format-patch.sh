#!/usr/bin/env bash

set -euo pipefail

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
patch_dir="$script_dir/v3-patch"

rm -rf "$patch_dir"

git format-patch master...HEAD \
    --base=origin/master \
    -o "$patch_dir/" \
    --reroll-count 3 \
    --to 'Jonathan Corbet <corbet@lwn.net>' \
    --cc 'Randy Dunlap <rdunlap@infradead.org>' \
    --cc 'Jens Axboe <axboe@kernel.dk>' \
    --cc 'Konstantin Khlebnikov <koct9i@gmail.com>' \
    --cc 'linux-doc@vger.kernel.org' \
    --cc 'linux-block@vger.kernel.org' \
    --cc 'linux-kernel@vger.kernel.org' \
    --cc 'David Reaver <me@davidreaver.com>'

"$script_dir/../../scripts/add-patch-comments.sh" "$patch_dir"/*.patch "$script_dir/patch-comments.txt"
