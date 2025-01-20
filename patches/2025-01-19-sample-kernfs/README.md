# Simple pseudo-filesystem sample build on top of `kernfs`

I'm working in my own `linux` tree in a branch called `davidreaver/sample-kernfs` and is located at <https://github.com/jdreaver/linux/tree/davidreaver/sample-kernfs> (diff URL: <https://github.com/jdreaver/linux/compare/master...jdreaver:linux:davidreaver/sample-kernfs>). I'm storing patches in this directory with:

```sh
cd ~/git/kernel-dev/linux
git switch davidreaver/sample-kernfs
git format-patch master...HEAD -o ../patches/2025-01-19-sample-kernfs/
```

## TODO

- Implement removing directories (kernfs_remove hangs when I do this)

  ```
  static int sample_kernfs_rmdir(struct kernfs_node *kn)
  {
  	// Free our sample_kernfs_directory struct, stored in the node's private
  	// data.
  	if (kn->priv)
  		kfree(kn->priv);

  	kernfs_remove(kn);
  	return 0;
  }

  static struct kernfs_syscall_ops sample_kernfs_kf_syscall_ops = {
  	.mkdir		= sample_kernfs_mkdir,
  	.rmdir		= sample_kernfs_rmdir,
  };
  ```

  - Probably locks!
    - cgroup calls `cgroup_kn_lock_live` which removes kernfs locks, it seems
    - sysfs doesn't get `rmdir` called in the context of VFS, so it doesn't have to deal with a kernfs lock
  - ChatGPT told me to remove `kernfs_remove`, which fixed the hang, but it says I need to be careful with locks and still remove the `kernfs` node somehow <https://chatgpt.com/c/678d91e1-ccec-8008-a3e1-93560dedaec7>
  - `rmdir` seems to be stuck in "State: D (disk sleep)". Is there something else I'm not doing?
    - Maybe some filesystem attribute I'm missing?
  - See how cgroups and sysfs do it.
    - They both seem to delete all children first. See `sysfs_remove_group` -> `sysfs/group.c:remove_files()`
  - Weird, maybe I have my new directories pointing to themselves as parents? Why is `sub1` a descendant?

    ```
    [   29.097861] kernfs sub1: removing descendants
    [   29.098449] kernfs sub1: removing leftmost descendant counter
    [   29.099352] kernfs sub1: removing leftmost descendant sub1
    ```

  - Debug tips:
    - Turn on debug logging
    - Lockup detection
    - ~~Try using perf to see where `rmdir` is stuck~~ (stuck in State: D (disk sleep))
- Test multiple sample_kernfs roots at once
- Implement resetting count
- Implement `sums` file
  - Consider reimplementing this as getting the sum of all _parents_ instead of children. I suspect parents is easier.
- In cover letter, mention how patches are split up (to demonstrate the "steps" of building a pseudo-filesystem on top of `kernfs`, where each step adds a feature).
- Either add documentation for `kernfs` in this patch series or mention that I want to add documentation.

## Cover letter (WIP)

This patch series creates a pseudo-filesystem built on top of kernfs in
samples/kernfs/.
