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

- I'm pretty sure we can't just big-bang migrate everything. There are way too many users of `struct dentry *` for debugfs nodes. Here is potentially a subset:

  ```
  % rg 'struct dentry \*.*debug.*' | wc -l
  855
  ```

  I think I should make this incremental:
  - Make `struct debugfs_node { struct dentry dentry };` like I have.
  - Make new functions with `node` in the name that use `debugfs_node`, like `struct dentry *debugfs_lookup(const char *name, struct dentry *parent);` -> `struct debugfs_node *debugfs_lookup_node(const char *name, struct debugfs_node *parent);`
  - Incrementally migrate users
    - Add a deprecation check for the non-`node` versions in `checkpatch.pl`
  - Once all users are migrated, nuke the old non-`node` functions

  I think this plan is good, except I'm sad we have to pollute all the names with `node`. `debugfs_lookup` and `debugfs_create_file` are just so much cleaner than `debugfs_lookup_node` and `debugfs_create_file_node`

- Get feedback on approach
