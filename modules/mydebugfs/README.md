# `mydebugfs`, a kernel module implementing an in-memory filesystem using `debugfs`

This kernel module is a followup to [`myfs`](../myfs). It uses `debugfs` to show some data to the user.

## Example usage

Here is a run of the test script:

```
# ./test.sh
...
+ insmod mydebugfs.ko
+ mydebugfs_root=/sys/kernel/debug/mydebugfs
+ ls -lah /sys/kernel/debug/mydebugfs
total 0
drwxr-xr-x  2 root root 0 Jan 18 18:28 .
drwx------ 26 root root 0 Jan 18 18:28 ..
-rw-r--r--  1 root root 0 Jan 18 18:28 mybool
-rw-r--r--  1 root root 0 Jan 18 18:28 mycounter
+ cat /sys/kernel/debug/mydebugfs/mybool
N
+ echo true
+ cat /sys/kernel/debug/mydebugfs/mybool
Y
+ echo 0
+ cat /sys/kernel/debug/mydebugfs/mybool
N
+ cat /sys/kernel/debug/mydebugfs/mycounter
0
+ cat /sys/kernel/debug/mydebugfs/mycounter
1
+ echo 5
+ cat /sys/kernel/debug/mydebugfs/mycounter
5
+ echo 0
+ cat /sys/kernel/debug/mydebugfs/mycounter
0
+ cat /sys/kernel/debug/mydebugfs/mycounter
```
