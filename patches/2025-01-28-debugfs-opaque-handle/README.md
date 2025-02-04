# Migrate `debugfs` to use and opaque pointer instead of dentry in its API

Related: [2025-01-19-sample-kernfs](../2025-01-19-sample-kernfs) and [2025-01-22-port-tracefs-kernfs](../2025-01-22-port-tracefs-kernfs).

Storing patches in this directory with:

```bash
git format-patch master...HEAD \
      --base=origin/master \
      -o ../patches/2025-01-28-debugfs-opaque-handle/v1-patches/ \
      --cover-letter \
      --description-file=../patches/2025-01-28-debugfs-opaque-handle/cover-letter-description.txt \
      --cover-from-description=subject \
      --rfc \
      --to 'Greg Kroah-Hartman <gregkh@linuxfoundation.org>' \
      --to 'Rafael J. Wysocki <rafael@kernel.org>' \
      --to 'Danilo Krummrich <dakr@kernel.org>' \
      --cc 'Steven Rostedt <rostedt@goodmis.org>' \
      --cc 'Christian Brauner <brauner@kernel.org>' \
      --cc 'Alexander Viro <viro@zeniv.linux.org.uk>' \
      --cc 'Tejun Heo <tj@kernel.org>' \
      --cc 'linux-fsdevel@vger.kernel.org' \
      --cc 'cocci@inria.fr' \
      --cc 'linux-kernel@vger.kernel.org' \
      --cc 'David Reaver <me@davidreaver.com>'
```

Different versions:

- [v0-patches](./v0-patches) Before Steve's suggestion of starting with a `#define`. This was meant to be RFC-only and each commit didn't compile until the last couple of them.
- [v1-patches](./v1-patches) Use `#define debugfs_node dentry` first so we can do subsequent transformations while still being able to compile each commit.

# TODO

## Not seeing build errors

Files I added `struct debugfs_node;` to:
- `include/linux/shrinker.h`
- `drivers/usb/host/ohci-dbg.c`
- `drivers/gpu/drm/imagination/pvr_params.h`

Facts:
- If I remove `#include <linux/debugfs.h>` in `include/drm/drm_connector.h`, then `make drivers/gpu/drm/drm_atomic_uapi.o` causes a compilation error with `defconfig`, but not `allyesconfig` or `allmodconfig`
- This only happens on the last commit, where I replace the `#define` with a real struct

Potential conclusions:
- I think what happens is make allyesconfig has more forward-defined `struct debugfs_node` entries. They get imported before implicit declarations of `debugfs_node` inside function callbacks. This is confirmed with compiling `make drivers/gpu/drm/drm_atomic_uapi.i` and comparing.
  - I think I need to find all places where `struct debugfs_node` is used as a _function_ parameter, and ensure I `#include <linux/debugfs.h>`

I should probably remove the `#define` in `dcache.h` as well so I really know where to add these `#include`s.

Cocinelle idea: make a cleanup step where we remove `struct dentry;` forward decls if a file no longer uses `dentry` (check for `debugfs_node` to find files that used to use `dentry`)

In run-spatch.sh, revert these files that added a forward decl:
- include/linux/file.h
- include/linux/fs_context.h
- include/linux/capability.h
- include/linux/kernfs.h
- include/linux/mount.h
- include/linux/security.h
- include/linux/statfs.h

How to generate all `.i` files:
- Add `KBUILD_CFLAGS += -save-temps=obj` to Makefile
- (hacky, doesn't quite work) `rg -l 'debugfs_node' -g "*.c" | sed 's/\.c$/.i/' | xargs make -k -j$(nproc)`

rg command that finds similar situations as drm_connector.h:

```
rg -l '\(\*[a-z]+.*struct debugfs_node' -g '*.h' | xargs rg --files-without-match '<linux/debugfs.h>'
```


Once I figure this out: move the extra includes to the commits where I actually change debugfs_node. Some of these are in the manual fixup commit, like the drm header files!

- Use `make drivers/gpu/drm/drm_atomic_uapi.i` to see headers getting loaded

Try this:

```
rm drivers/gpu/drm/drm_atomic_uapi.o && make KCFLAGS="-H" drivers/gpu/drm/drm_atomic_uapi.o > ../allyesconfig-flags.log 2>&1
```

If I remove `#include <linux/debugfs.h>` in `include/drm/drm_connector.h`, I see a build error when I do my QEMU minimal build, but not with `allmodconfig`.

- Files compiled were `drivers/gpu/drm/drm_atomic.o` and `drivers/gpu/drm/drm_atomic_uapi.o`:
  - Compile these directly under different configs
    - I don't see different `-I` options. Something else is happening.
  - Compile with extra verbosity to see the difference when compiling these files. Maybe another directory is being included.
  - Diff my minimal config, allyesconfig, and allmodconfg .config files
  - I think this is an allyesconfig vs allmodconfig thing. drm_atomic.o is under drm-y

```
In file included from ./include/drm/drm_modes.h:33,
                 from ./include/drm/drm_crtc.h:32,
                 from ./include/drm/drm_atomic.h:31,
                 from drivers/gpu/drm/drm_atomic_uapi.c:31:
./include/drm/drm_connector.h:1579:70: error: ‘struct debugfs_node’ declared inside parameter list will not be visible outside of this definition or declaration [-Werror]
 1579 |         void (*debugfs_init)(struct drm_connector *connector, struct debugfs_node *root);
      |
```

- Consider the following rule: if a _header_ file defines a function with `debugfs_struct` at all, then it needs `#include <linux/debugfs.h>`.
  - We could check for this after running Coccinelle (maybe even also manual fixups) and then backport these `#include`s to an earlier commit.
- If I don't see any errors in my latest mrproper build, undo one of the recent header changes (e.g. the `#include` in `include/drm/drm_connector.h`) and make sure the error triggers in a full build. If it doesn't, figure out why.
  - Should I be using `allyesconfig` instead of `allmodconfig`? I wonder if we somehow aren't type checking when we are compiling standalone modules? (seems implausible to me)


## Submitting, final checks

- (maybe not, Linus' tree is farther ahead) Rebase against `git://git.kernel.org/pub/scm/linux/kernel/git/gregkh/driver-core.git`
- Ensure all commits have change logs and signoffs.
- Update coccinelle script in the change log of the commit that uses it.
- Actually go through testing again before submitting!
- Check for TODO items in patches
- Ensure I have latest cover letter (run `git format-patch`)
- Run checkpatch.pl
- Use clang or a different nix-shell for cross-compilation (and add that I did that to test procedure)
  - At least try arm, powerpc, s390, and mips
- Make sure each commit compiles, not just the last one. This runs a build for each commit on the branch (since `master` is the base branch):

  ```
  time git rebase --exec 'git show --quiet --pretty=format:"%h %s" && make -s mrproper && make -s allyesconfig && time make -s -j16 && echo Success!' master
  time git rebase --exec 'git show --quiet --pretty=format:"%h %s" && make -s mrproper && make -s allyesconfig && ./scripts/config --set-val CONFIG_DEBUGFS n && make oldconfig && time make -s -j16 && echo Success!' master
  time git rebase --exec 'git show --quiet --pretty=format:"%h %s" && make -s mrproper && make -s defconfig && time make -s -j16 && echo Success!' master
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
