# Linux kernel patches

This directory contains various patches I've made to the kernel.

## Replacing `kmap_atomic` with `kmap_local_page`

See README in first patch for details:

Remaining `kmap_atomic` usages: [remaining-kmap-atomic-usages.txt](./2025-01-07-drivers-dm-kmap-local-page/remaining-kmap-atomic-usages.txt)

Patches:

- [2025-01-07-drivers-dm-kmap-local-page](./2025-01-07-drivers-dm-kmap-local-page)
- [2025-01-08-virtio-console-kmap-local-page](./2025-01-08-virtio-console-kmap-local-page)
- [2025-01-10-pm-snapshot-kmap-local-page](./2025-01-10-pm-snapshot-kmap-local-page)

## Filesystem-related

- [2025-01-19-sample-kernfs](./2025-01-19-sample-kernfs)
- [2025-01-22-port-tracefs-kernfs](./2025-01-22-port-tracefs-kernfs)
- [2025-01-28-debugfs-opaque-handle](./2025-01-28-debugfs-opaque-handle)
- [2025-02-10-relay-debugfs-simplification](./2025-02-10-relay-debugfs-simplification)

## Misc

- [2022-06-25-scripts-get-feat-usr-bin-env-perl](./2022-06-25-scripts-get-feat-usr-bin-env-perl)
- [2025-01-08-remove-checkpatch-old-deprecated-apis](./2025-01-08-remove-checkpatch-old-deprecated-apis)
