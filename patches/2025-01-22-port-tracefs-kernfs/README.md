# Port `tracefs` to use `kernfs`

## Background

Related: [2025-01-19-sample-kernfs](../2025-01-19-sample-kernfs)

Prior art: draft patch from Jan 31 2024 [Port tracefs to kernfs](https://lore.kernel.org/all/20240131-tracefs-kernfs-v1-0-f20e2e9a8d61@kernel.org/T/#u) by Christian Brauner.

## Ideas for splitting this up

- Have eventfs use totally isolated data structures so moving tracefs by itself is easier. Move anything shared to `event_inode.c`.
