# `myfs`, a kernel module implementing an in-memory filesystem

This kernel implements a very simple in-memory filesystem using a Linux Kernel Module.

# TODO

- Try simpler filesystem with files pre-made first, like in <https://lwn.net/Articles/57369/>
  - Updated code, maybe <https://gist.github.com/RadNi/9d8a074e6264c1664b97b8eee11b1d2a>

Figure out permission denied when creating file. Useful gdb breakpoint:

```
break path_openat where $_streq(nd->name->name, "/mnt/myfs/hello")
```
