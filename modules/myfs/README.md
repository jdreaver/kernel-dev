# `myfs`, a kernel module implementing an in-memory filesystem

This kernel implements a very simple in-memory filesystem using a Linux Kernel Module.

## Example usage

Here is a run of the test script:

```
# ./test.sh
...
+ mount_point=/mnt/myfs
...
+ insmod myfs.ko
+ grep myfs /proc/filesystems
nodev	myfs
+ mkdir -p /mnt/myfs
+ mount -t myfs myfs /mnt/myfs
+ echo 'Hello, world!'
+ cat /mnt/myfs/hello.txt
Hello, world!
+ ls -lah /mnt/myfs
total 4.0K
drwxr-xr-x 2 root root    0 Jan 17 21:44 .
drwxr-xr-x 4 root root 4.0K Jan 17 21:44 ..
-rw-r--r-- 1 root root    0 Jan 17 21:44 hello.txt
```
