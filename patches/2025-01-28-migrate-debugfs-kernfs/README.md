# Migrate `debugfs` to use `kernfs` under the hood

Related: [2025-01-19-sample-kernfs](../2025-01-19-sample-kernfs) and [2025-01-22-port-tracefs-kernfs](../2025-01-22-port-tracefs-kernfs).

Storing patches in this directory with:

```bash
git format-patch master...HEAD \
      --base=origin/master \
      -o ../patches/2025-01-28-migrate-debugfs-kernfs/ \
      --cover-letter \
      --to 'Greg Kroah-Hartman <gregkh@linuxfoundation.org>' \
      --to 'Steven Rostedt <rostedt@goodmis.org>' \
      --cc 'Tejun Heo <tj@kernel.org>' \
      --cc 'Christian Brauner <brauner@kernel.org>' \
      --cc 'linux-fsdevel@vger.kernel.org' \
      --cc 'linux-kernel@vger.kernel.org'
```

# TODO

- Find best "opaque" type
  - `struct debugfs_node { dentry dentry }` (returning pointer to this): could work. Just cast `dentry` to/from this (and `*dentry` to/from `*debugfs_node`)
  - `struct debugfs_node { dentry *dentry }`: Nice, but the main problem is dealing with `IS_ERR` return values. We have to return a pointer.
