# `relay` simplification and `debugfs` usage

In my v1 RFC for [2025-01-28-debugfs-opaque-handle](../2025-01-28-debugfs-opaque-handle), Greg KH suggested I simplify some debugfs subsystems/drivers so they don't need so much from the dentry. I had touched relay in my series as a separate commit, and he said that was a good example.

<https://lore.kernel.org/linux-fsdevel/2025021048-thieving-failing-7831@gregkh/>:

> And finally, I think that many of the places where you did have to
> convert the code to save off a debugfs node instead of a dentry can be
> removed entirely as a "lookup this file" can be used instead.  I was
> waiting for more conversions of that logic, removing the need to store
> anything in a driver/subsystem first, before attempting to get rid of
> the returned dentry pointer.
>
> As an example of this, why not look at removing almost all of those
> pointers in the relay code?  Why is all of that being stored at all?

# Work

Storing patches in this directory by calling `$this_dir/format-patch.sh` from the `linux` source tree:

```bash
../patches/2025-02-10-relay-debugfs-simplification/format-patch.sh
```

# Before submitting

- Ask Greg KH permission for adding suggested-by
- checkpatch.pl
- Make sure each commit compiles, not just the last one. This runs a build for each commit on the branch (since `master` is the base branch):

  ```
  time git rebase --exec 'git show --quiet --pretty=format:"%h %s" && make -s mrproper && make -s allmodconfig && time make -s -j$(nproc) && echo Success!' master
  ```

# Testing

I used blktrace:

```
  [shell 1] # blktrace -d /dev/sda

  [shell 2] # nproc
  4
  [shell 2] # ls /sys/kernel/debug/block/sda/trace*
  /sys/kernel/debug/block/sda/trace0  /sys/kernel/debug/block/sda/trace2
  /sys/kernel/debug/block/sda/trace1  /sys/kernel/debug/block/sda/trace3

  [shell 1] ^C
  === sda ===
    CPU  0:                   14 events,        1 KiB data
    CPU  1:                   33 events,        2 KiB data
    CPU  2:                   64 events,        4 KiB data
    CPU  3:                   29 events,        2 KiB data
    Total:                   140 events (dropped 0),        7 KiB data

  [shell 2] # ls /sys/kernel/debug/block/sda/trace*
  ls: cannot access '/sys/kernel/debug/block/sda/trace*': No such file or directory
```

# Kernel configuration

```
make defconfig kvm_guest.config
./scripts/kconfig/merge_config.sh -m .config ../patches/2025-02-10-relay-debugfs-simplification/relay-drivers.config
make olddefconfig
```

Files to compile:

```
make -j$(nproc) \
  kernel/relay.o \
  kernel/trace/blktrace.o \
  drivers/net/wwan/t7xx/t7xx_port_trace.o \
  drivers/net/wwan/iosm/iosm_ipc_trace.o \
  drivers/net/wireless/ath/ath9k/common-spectral.o \
  drivers/net/wireless/ath/ath11k/spectral.o \
  drivers/net/wireless/ath/ath10k/spectral.o \
  drivers/net/wireless/mediatek/mt76/mt7915/debugfs.o \
  drivers/net/wireless/mediatek/mt76/mt7996/debugfs.o \
  drivers/gpu/drm/i915/gt/uc/intel_guc_log.o
```
