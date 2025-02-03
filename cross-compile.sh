#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "Usage: $0 <arch>"
    echo "Available archs:"
    (cd flake && \
         nix eval --impure --expr 'builtins.attrNames (builtins.getFlake (toString ./.)).outputs.devShells.x86_64-linux' --json \
         | jq .[] -r \
         | sed 's/^/  /')
    exit 1
fi

arch=$1

exec nix develop "./flake#$arch" -c "$SHELL"
