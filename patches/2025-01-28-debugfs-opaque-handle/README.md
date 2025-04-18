# Migrate `debugfs` to use and opaque pointer instead of dentry in its API

Related: [2025-01-19-sample-kernfs](../2025-01-19-sample-kernfs) and [2025-01-22-port-tracefs-kernfs](../2025-01-22-port-tracefs-kernfs).

Storing patches in this directory with:

```bash
rm -rf ../patches/2025-01-28-debugfs-opaque-handle/v2-patches && \
  git format-patch master...HEAD \
      --base=origin/master \
      -o ../patches/2025-01-28-debugfs-opaque-handle/v2-patches/ \
      --cover-letter \
      --description-file=../patches/2025-01-28-debugfs-opaque-handle/cover-letter-description.txt \
      --cover-from-description=subject \
      --reroll-count=2 \
      --rfc \
      --to 'Greg Kroah-Hartman <gregkh@linuxfoundation.org>' \
      --to 'Rafael J. Wysocki <rafael@kernel.org>' \
      --to 'Danilo Krummrich <dakr@kernel.org>' \
      --cc 'Steven Rostedt <rostedt@goodmis.org>' \
      --cc 'Christian Brauner <brauner@kernel.org>' \
      --cc 'Alexander Viro <viro@zeniv.linux.org.uk>' \
      --cc 'linux-fsdevel@vger.kernel.org' \
      --cc 'cocci@inria.fr' \
      --cc 'linux-kernel@vger.kernel.org' \
      --cc 'David Reaver <me@davidreaver.com>'
```

Different versions:

- [v0-patches](./v0-patches) Before Steve's suggestion of starting with a `#define`. This was meant to be RFC-only and each commit didn't compile until the last couple of them.
- [v1-patches](./v1-patches) Use `#define debugfs_node dentry` first so we can do subsequent transformations while still being able to compile each commit.
  - Lore thread: <https://lore.kernel.org/linux-fsdevel/20250210052039.144513-1-me@davidreaver.com/T/#u>
- [v2-patches](./v2-patches) Changes after feedback on v1.

# Changes for v2

Send these as a response to the v1 RFC thread to see if anyone objects to these, or has more suggestions.

- (Al and Greg) Don't embed dentry in debugfs_node
  - Need to get consensus on alternative
  - We could do `struct debugfs_node { struct dentry *dentry; }` and return `struct debugfs_node` everywhere instead of `struct debugfs_node *`, but when the internal structure of `debugfs_node` changes, we would need another migration to return pointers. It would certainly be an easier migration at least.
    - Could call it `struct debugfs_dentry` so it is clear what the intent is.
  - Consider lifetimes even if we embed a dentry pointer. We need to ensure that users of `debugfs_node_dentry()` do not free the dentry, for example.
- Fix more compilation errors (kernel test robot sent me some)
- (Greg) Refactor code that requires underlying access to the dentry so it no longer needs that.
  - Consider asking Greg to expand on his point about refactoring users to remove the need to store anything.
  - After that, it is okay to expose the underlying dentry via `debugfs_node_dentry`. Don't make so many wrapper functions.
- Incorporate [2025-02-10-relay-debugfs-simplification](../2025-02-10-relay-debugfs-simplification/) into this patch set or send it off alone
  - Make sure to include testing comments in patch
- (Steve) Replace temporary defines and forward declarations with #include <linux/debugfs.h>.
  - Coccinelle might not be the right tool for the job, but try Coccinelle first.

Greg's email for reference:

> First off, many thanks for attempting this, I didn't think it was ready
> to even be attempted, so it's very nice to see this.
>
> That being said, I agree with Al, we can't embed a dentry in a structure
> like that as the lifecycles are going to get messy fast.
>
> Also, your replacement of many of the dentry functions with wrappers
> seems at bit odd, ideally you would just return a dentry from a call
> like "debugfs_node_to_dentry()" and then let the caller do with it what
> it wants to, that way you don't need to wrap everything.
>
> And finally, I think that many of the places where you did have to
> convert the code to save off a debugfs node instead of a dentry can be
> removed entirely as a "lookup this file" can be used instead.  I was
> waiting for more conversions of that logic, removing the need to store
> anything in a driver/subsystem first, before attempting to get rid of
> the returned dentry pointer.
>
> As an example of this, why not look at removing almost all of those
> pointers in the relay code?  Why is all of that being stored at all?
>
> Oh, also, all of those forward declarations look really odd, something
> feels wrong with needing that type of patch if we are doing things
> right.  Are you sure it was needed?
>
> thanks,
>
> greg k-h

# Why do we need the forward declarations?

(Reviewers asked this, so I'm coming up with concrete answers.)

## Example removing all the `#define debugfs_node dentry` lines added in the Coccinelle commit

`find . -type f \( -name "*.c" -o -name "*.h" \) -exec sed -i '/#define debugfs_node/d' {} +` (undo changes to `debugfs.h` and `dcache.h`)

If you compile allmodconfig, you get:

```
In file included from drivers/gpu/drm/xe/xe_gsc_debugfs.c:6:
drivers/gpu/drm/xe/xe_gsc_debugfs.h:12:57: error: ‘struct debugfs_node’ declared inside parameter list will not be visible outside of this definition or declaration [-Werror]
   12 | void xe_gsc_debugfs_register(struct xe_gsc *gsc, struct debugfs_node *parent);
      |                                                         ^~~~~~~~~~~~
drivers/gpu/drm/xe/xe_gsc_debugfs.c:51:6: error: conflicting types for ‘xe_gsc_debugfs_register’; have ‘void(struct xe_gsc *, struct dentry *)’
   51 | void xe_gsc_debugfs_register(struct xe_gsc *gsc, struct debugfs_node *parent)
      |      ^~~~~~~~~~~~~~~~~~~~~~~
drivers/gpu/drm/xe/xe_gsc_debugfs.h:12:6: note: previous declaration of ‘xe_gsc_debugfs_register’ with type ‘void(struct xe_gsc *, struct debugfs_node *)’
   12 | void xe_gsc_debugfs_register(struct xe_gsc *gsc, struct debugfs_node *parent);
      |      ^~~~~~~~~~~~~~~~~~~~~~~
```

and

```
drivers/ufs/core/ufs-fault-injection.c: In function ‘ufs_fault_inject_hba_init’:
drivers/ufs/core/ufs-fault-injection.c:69:59: error: passing argument 2 of ‘fault_create_debugfs_attr’ from incompatible pointer type [-Werror=incompatible-pointer-types]
   69 |         fault_create_debugfs_attr("trigger_eh_inject", hba->debugfs_root, &hba->trigger_eh_attr);
      |                                                        ~~~^~~~~~~~~~~~~~
      |                                                           |
      |                                                           struct dentry *
In file included from drivers/ufs/core/ufs-fault-injection.c:5:
./include/linux/fault-inject.h:83:46: note: expected ‘struct debugfs_node *’ but argument is of type ‘struct dentry *’
   83 |                         struct debugfs_node *parent, struct fault_attr *attr);
      |                         ~~~~~~~~~~~~~~~~~~~~~^~~~~~
drivers/ufs/core/ufs-fault-injection.c:70:56: error: passing argument 2 of ‘fault_create_debugfs_attr’ from incompatible pointer type [-Werror=incompatible-pointer-types]
   70 |         fault_create_debugfs_attr("timeout_inject", hba->debugfs_root, &hba->timeout_attr);
      |                                                     ~~~^~~~~~~~~~~~~~
      |                                                        |
      |                                                        struct dentry *
./include/linux/fault-inject.h:83:46: note: expected ‘struct debugfs_node *’ but argument is of type ‘struct dentry *’
   83 |                         struct debugfs_node *parent, struct fault_attr *attr);
```

# TODO

I'm considering putting my remaining problems in the RFC and asking for suggestions.

## Not seeing build errors

A few errors on arm allmodconfig in drivers. I think all of these are from implicit `struct debugfs_node` declarations in structs, which are distinct from `struct dentry` because of the `#define`. We might need to do `#define debugfs_node dentry` more :(

```
In file included from ./include/linux/mmc/host.h:13,
                 from drivers/mmc/core/mmc_test.c:8:
drivers/mmc/core/mmc_test.c: In function ‘__mmc_test_register_dbgfs_file’:
drivers/mmc/core/mmc_test.c:3199:60: error: passing argument 3 of ‘debugfs_create_file_full’ from incompatible pointer type [-Werror=incompatible-pointer-types]
 3199 |                 file = debugfs_create_file(name, mode, card->debugfs_root,
      |                                                        ~~~~^~~~~~~~~~~~~~
      |                                                            |
      |                                                            struct debugfs_node *


drivers/gpu/drm/drm_panic.c: In function ‘debugfs_register_plane’:
drivers/gpu/drm/drm_panic.c:776:52: error: passing argument 3 of ‘debugfs_create_file_full’ from incompatible pointer type [-Werror=incompatible-pointer-types]
  776 |         debugfs_create_file(fname, 0200, plane->dev->debugfs_root,
      |                                          ~~~~~~~~~~^~~~~~~~~~~~~~
      |                                                    |
      |                                                    struct debugfs_node *


drivers/mtd/mtdswap.c: In function ‘mtdswap_add_debugfs’:
drivers/mtd/mtdswap.c:1257:37: error: initialization of ‘struct dentry *’ from incompatible pointer type ‘struct debugfs_node *’ [-Werror=incompatible-pointer-types]
 1257 |         struct debugfs_node *root = d->mtd->dbg.dfs_dir;
      |
```

Continue trying to find files that might not be defining debugfs_node:
- If I do this, call it out in cover letter.
- Run with the augmented Makefile and then run my script (do this on EC2)
- Think about Coccinelle improvements. I think adding the `#define` after _any_ top-level struct if dentry isn't there is fine?
- rg for any .h files with debugfs_node that do not have a `struct debugfs_node;`
  - A more interesting case is specifically searching for files that have `struct debugfs_node` not at the beginning of a line, because it is probably a struct definition or function arg: '\s+.*struct debugfs_node '

How to generate all `.i` files:
- Add `KBUILD_CFLAGS += -save-temps=obj` to Makefile
- (hacky, doesn't quite work) `rg -l 'debugfs_node' -g "*.c" | sed 's/\.c$/.i/' | xargs make -k -j$(nproc)`

Try this:

```
rm drivers/gpu/drm/drm_atomic_uapi.o && make KCFLAGS="-H" drivers/gpu/drm/drm_atomic_uapi.o > ../allyesconfig-flags.log 2>&1
```

## Submitting, final checks

- (maybe not, Linus' tree is farther ahead) Rebase against `git://git.kernel.org/pub/scm/linux/kernel/git/gregkh/driver-core.git`
- Rerun the Coccinelle commit to make sure it is accurate.
- Update coccinelle script in the change log of the commit that uses it.
- Remove stuff in cleanup commit that just does something trivial, like remove `struct dentry;`. Don't add extra cleanups.
- Actually go through testing again before submitting!
- Ensure all commits have change logs and signoffs.
- Ensure `remove-dentry-define.sh` is run again
- Check for TODO items in patches
- Ensure I have latest cover letter (run `git format-patch`)
- Run checkpatch.pl
- Use clang or a different nix-shell for cross-compilation
  - To install these on Ubuntu: `sudo apt-get install gcc-aarch64-linux-gnu gcc-arm-linux-gnueabi gcc-mips-linux-gnu gcc-powerpc-linux-gnu gcc-powerpc64-linux-gnu gcc-s390x-linux-gnu`
  - ARCH=powerpc CROSS_COMPILE=powerpc64-linux-gnu-
  - ARCH=s390 CROSS_COMPILE=s390x-linux-gnu-
  - ARCH=arm CROSS_COMPILE=arm-linux-gnueabi-
  - (Just do powerpc64) ARCH=powerpc CROSS_COMPILE=powerpc-linux-gnu-
  - (doesn't work) ARCH=mips CROSS_COMPILE=mips-linux-gnu-

```
make -s mrproper
make ARCH=powerpc -s defconfig
time git rebase --exec 'git show --quiet --pretty=format:"%h %s" && time make -s ARCH=powerpc CROSS_COMPILE=powerpc-linux-gnu- -j$(nproc) && echo Success!' master
```

- Make sure each commit compiles, not just the last one. This runs a build for each commit on the branch (since `master` is the base branch):

  ```
  time git rebase --exec 'git show --quiet --pretty=format:"%h %s" && make -s mrproper && make -s allyesconfig && time make -s -j$(nproc) && echo Success!' master
  time git rebase --exec 'git show --quiet --pretty=format:"%h %s" && make -s mrproper && make -s allyesconfig && ./scripts/config --set-val CONFIG_DEBUG_FS n && make olddefconfig && time make -s -j$(nproc) && echo Success!' master
  time git rebase --exec 'git show --quiet --pretty=format:"%h %s" && make -s mrproper && make -s defconfig && time make -s -j$(nproc) && echo Success!' master
  ```

## Non-coccinelle changes

- Try removing a few `debugfs_node_dentry` calls. I think they are only used for `%pd2` printf'ing and fetching a parent.
  - Consider a `->d_parent` -> new helper `debugfs_node_parent` and add to Coccinelle as well

## Coccinelle

- In `include/media/v4l2-async.{c,h}`, `v4l2_async_debug_init` is getting transformed in the .c file, but not in the .h file.

- Consider having coccinelle script rename variables named `dentry` and `dent` to `node`. Higher likelihood of merge conflicts though.

- Pretty simple case not getting handled: `struct dentry *direct = blah->foo;` where `foo` was just migrated from dentry to debugfs_node. `direct` remains `dentry`

- `sound/soc/soc-pcm.c` isn't working (only file I think). It interesting because there is no dentry declaration in the actual file (but there is debugfs usage)
  - (old TODO) `include/sound/soc.h` has a `struct dentry *debugfs_dpcm_root;` field that refuses to get matches. I think all the `#define`s in the file are screwing with Coccinelle, because it works when I move that struct to my test file.

- Test more complex assignments like `hb->dbgfs.base_dir = debugfs_create_dir("heartbeat", accel_dev->debugfs_dir);` in test file

- Nested structs like

  ```
  struct tegra_emc {
  	struct device *dev;
          ...
  	struct {
  		struct debugfs_node *root;
  		unsigned long min_rate;
  		unsigned long max_rate;
  	} debugfs;
          ...
  };
  ```

- Consider removing the `all_function_calls` thing and replacing it with: `identifier f = {identifier wrapper_function_returns.wfr, identifier wrapper_function_args.wfa, ... };`

- Manual stuff:
  - arch/s390 iterates through some array of debugfs dentries <https://github.com/jdreaver/linux/blob/05dbaf8dd8bf537d4b4eb3115ab42a5fb40ff1f5/arch/s390/kernel/debug.c#L671>

## Coccinelle automation

Good directories/files to test:
- `drivers/cxl/cxlmem.h` and `drivers/cxl/mem.c` lots of wrapper functions
- drivers/gpio
- lib/kunit (includes both source e.g. `lib/kunit/debugfs.c` and a header in `include/kunit/test.h`)
- Contains wrapper functions that wrap debugfs:
  - fault-inject.{c,h}
  - arch/x86/kernel/kdebugfs.c
  - arch/x86/xen has `struct dentry * __init xen_init_debugfs(void);`
  - arch/x86/kvm/debugfs.c
  - block/blk-{core,timeout}.c _uses_ `fault_create_debugfs_attr`, which is defined in fault-inject.{c,h}
- mm/shrinker_debug.c has an initializer after a `dentry *` declaration
- mtk-svs.c has a triple declaration of dentry (e.g. `struct dentry *a, *b, *c;`)
- drivers/scsi/lpfc/ has many dentry struct fields in a row
- `sound/soc/soc-pcm.c` is interesting because there is no dentry declaration in the actual file
- Tripped up spatch when run against entire tree
  - `drivers/net/netdevsim/netdevsim.h`
  - `include/linux/mlx5/driver.h`
  - `bnxt_re.h` has an even simpler one that wasn't caught
  - `drivers/crypto/intel/qat/qat_common/adf_cfg.c` (and `.h`)
- `drivers/gpu/drm/amd/amdgpu/amdgpu_ras_eeprom.c` has `struct dentry *de = ras->de_ras_eeprom_table` and a `d_inode`

Run patch script with (note that `--in-place` doesn't appear to work):

```
$ time spatch ../patches/2025-01-28-debugfs-opaque-handle/script.cocci --all-includes --include-headers --jobs 14 . --timeout 0 --tmp-dir /tmp/cocci-run/ > patch.patch 2> spatch-stderr.log
$ patch -p1 < patch.patch
```

(not needed anymore) Fixup one-liner for multi-declarations:

```
$ find . -type f \( -name "*.c" -o -name "*.h" \) -exec sed -i -E ':a;s/(struct debugfs_node \*[^;]+);struct debugfs_node \*/\1, */g;ta; s/struct \*debugfs_node /struct debugfs_node */g' {} +
```

## Finding all usages

Steve suggested we do the opaque pointer migration in one go. I need to make sure I get _everything_ in this case:

- Automation idea: I think I can use `rg` to find all users of the debugfs API and clang-query `to` figure out the types of variables that used to be `dentry`. Then I can ask for the variable definition and edit those types, perhaps using coccinelle in the pipeline somewhere too.
- Compile with `make allmodconfig` or `make allyesconfig`
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

## All debugfs API functions (from debugfs.hs)

List of names (in case we want to use this in coccinelle):

```
debugfs_attr_read
debugfs_attr_write
debugfs_attr_write_signed
debugfs_change_name
debugfs_create_atomic_t
debugfs_create_automount
debugfs_create_bool
debugfs_create_devm_seqfile
debugfs_create_dir
debugfs_create_file
debugfs_create_file_aux
debugfs_create_file_aux_num
debugfs_create_file_full
debugfs_create_file_short
debugfs_create_file_size
debugfs_create_file_unsafe
debugfs_create_regset32
debugfs_create_size
debugfs_create_str
debugfs_create_symlink
debugfs_create_u16
debugfs_create_u32
debugfs_create_u32_array
debugfs_create_u64
debugfs_create_u8
debugfs_create_ulong
debugfs_create_x16
debugfs_create_x32
debugfs_create_x64
debugfs_create_x8
debugfs_enter_cancellation
debugfs_file_get
debugfs_file_put
debugfs_get_aux
debugfs_get_aux_num
debugfs_initialized
debugfs_leave_cancellation
debugfs_lookup
debugfs_lookup_and_remove
debugfs_node
debugfs_node_get
debugfs_node_path_raw
debugfs_node_put
debugfs_print_regs32
debugfs_read_file_bool
debugfs_read_file_str
debugfs_real_fops
debugfs_remove
debugfs_remove_recursive
debugfs_write_file_bool
```
