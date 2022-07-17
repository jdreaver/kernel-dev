#!/usr/bin/env bash

# Updates the nix flake and diffs the profiles

set -eu

rm -f old-profile new-profile

nix build .#devShells.x86_64-linux.default --out-link ./old-profile

nix flake update

nix build .#devShells.x86_64-linux.default --out-link ./new-profile

nix store diff-closures ./old-profile ./new-profile

rm -f old-profile new-profile
