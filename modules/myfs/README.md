# `myfs`, a kernel module implementing an in-memory filesystem

This kernel implements a very simple in-memory filesystem using a Linux Kernel Module.

# TODO

- Remove the extra `dget` in `myfs_mknod`. Figure out how to properly keep the `dentry` around.
