# Migrate `debugfs` to use `kernfs` under the hood

Related: [2025-01-19-sample-kernfs](../2025-01-19-sample-kernfs) and [2025-01-22-port-tracefs-kernfs](../2025-01-22-port-tracefs-kernfs).

Storing patches in this directory with:

```bash
git format-patch master...HEAD \
      --base=origin/master \
      -o ../patches/2025-01-28-debugfs-opaque-handle/ \
      --cover-letter \
      --to 'Greg Kroah-Hartman <gregkh@linuxfoundation.org>' \
      --to 'Rafael J. Wysocki <rafael@kernel.org>' \
      --to 'Danilo Krummrich <dakr@kernel.org>' \
      --cc 'Steven Rostedt <rostedt@goodmis.org>' \
      --cc 'Christian Brauner <brauner@kernel.org>' \
      --cc 'linux-fsdevel@vger.kernel.org' \
      --cc 'linux-kernel@vger.kernel.org'
```

# TODO

- Make another commit before (or after? or both?) the commit where we apply coccinelle with manual fixups while we get coccinelle working.
- Script is overreaching:
  - (most concerning one) Line 679 in `inode.c`, `struct dentry *dentry_ptr;` is getting touched
  - `struct dentry *d_parent;` in `dentry` in `include/linux/dcache.h`
  - `struct dentry *root;` in `fs_context` in `include/linux/fs_context.h`
- Script isn't doing enough:
  - In `kvm_host.h`: `void kvm_arch_create_vcpu_debugfs(struct kvm_vcpu *vcpu, struct dentry *debugfs_dentry);`. The actual function definition is getting modified, but not the header file. I might need to handle these differently.
    - Can I run spatch against header files directly?
  - `drivers/bus/moxtet.c` not matching anything, but clearly it needs to <https://github.com/jdreaver/linux/blob/bdc4ca114ce02b5c7aa23dee1a7aad41f6cc1da6/drivers/bus/moxtet.c#L553-L578>
    - Problem is `struct dentry *root, *entry;` on one line
  - block/blk-{core,timeout}.c _uses_ `fault_create_debugfs_attr`, which is defined in fault-inject.{c,h}, but doesn't modify the return argument.
    - I wonder if I can make the script more general so that for a given list of functions, both change the function definition and "infect" all users of it.
    - Same for `xen_init_debugfs`

- Get feedback on approach
- Try to make it impossible for users to access dentry. Move struct definition to some "internal.h" file
- Consider reducing casts by using helper functions to convert to/from dentry
  - Less important if users can't access dentry
- If we eventually want to use `kernfs`, we need to consider `file_operations` as well. That would be a super hard thing to migrate across all of the kernel.
  - Maybe not actually. There are lots of helper macros being used by debugfs users that will make this easier.

## Coccinelle automation

Good directories to test:
- drivers/gpio
- lib/kunit (includes both source e.g. `lib/kunit/debugfs.c` and a header in `include/kunit/test.h`)
- Contains wrapper functions that wrap debugfs:
  - fault-inject.{c,h}
  - arch/x86/kernel/kdebugfs.c
  - arch/x86/xen has `struct dentry * __init xen_init_debugfs(void);`
  - arch/x86/kvm/debugfs.c
  - block/blk-{core,timeout}.c _uses_ `fault_create_debugfs_attr`, which is defined in fault-inject.{c,h}

Run patch script with (note that `--in-place` doesn't appear to work):

```
$ spatch ../patches/2025-01-28-debugfs-opaque-handle/structured.cocci --all-includes . > patch.patch
$ patch -p1 < patch.patch
```

Ideas:
- It is okay if this catches _too_ much. We can fix things up.

## Finding all usages

Steve suggested we do the opaque pointer migration in one go. I need to make sure I get _everything_ in this case:

- Automation idea: I think I can use `rg` to find all users of the debugfs API and clang-query `to` figure out the types of variables that used to be `dentry`. Then I can ask for the variable definition and edit those types, perhaps using coccinelle in the pipeline somewhere too.
- Compile with `makeallyesconfig`
- Manually grep public debugfs APIs to make sure I covered everything
- Re-check my query (and as I do this, think of other things to grep for)

  ```
  $ rg 'struct dentry \*.*(debug|dbg).*' | wc -l
  1009
  $ rg '(debug|dbg).*struct dentry \*' | wc -l
  258
  ```

  Alternatively:

  ```
  $ rg 'struct dentry \*.*(debug|dbg).*' --files-with-matches | wc -l
  662
  $ rg '(debug|dbg).*struct dentry \*' --files-with-matches | wc -l
  141
  ```

- Write a script to get filenames for the union of all of the previous search methods and ensure they are in the diff

## (Old) Incremental idea

I'm pretty sure we can't just big-bang migrate everything. There are way too many users of `struct dentry *` for debugfs nodes. Here is potentially a subset:

```
$ rg 'struct dentry \*.*(debug|dbg).*' | wc -l
1009
```

I think I should make this incremental:
- Make `struct debugfs_node { struct dentry dentry };` like I have.
- Make new functions with `node` in the name that use `debugfs_node`, like `struct dentry *debugfs_lookup(const char *name, struct dentry *parent);` -> `struct debugfs_node *debugfs_lookup_node(const char *name, struct debugfs_node *parent);`
- Incrementally migrate users
  - Add a deprecation check for the non-`node` versions in `checkpatch.pl`
- Once all users are migrated, nuke the old non-`node` functions

I think this plan is good, except I'm sad we have to pollute all the names with `node`. `debugfs_lookup` and `debugfs_create_file` are just so much cleaner than `debugfs_lookup_node` and `debugfs_create_file_node`
