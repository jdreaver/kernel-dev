# Replace `kmap_atomic` with `kmap_local_page` in `kernel/power/snapshot.c`

Status: not sent

Very similar to [2025-01-07-drivers-dm-kmap-local-page](../2025-01-07-drivers-dm-kmap-local-page/README.md) but much smaller (a single call site).

## TODO

- [x] Generate patch
- [ ] Testing
  - Test hibernation with my new Debian QEMU image that has swap
  - Test hibernation again with x86, CONFIG_HIGHMEM, and e.g. 8 GB of RAM
- [ ] Send
