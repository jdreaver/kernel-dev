# Migrate `debugfs` to use `kernfs` under the hood

Related: [2025-01-19-sample-kernfs](../2025-01-19-sample-kernfs) and [2025-01-22-port-tracefs-kernfs](../2025-01-22-port-tracefs-kernfs).

Storing patches in this directory with:

```bash
git format-patch master...HEAD \
      --base=origin/master \
      -o ../patches/2025-01-28-debugfs-opaque-handle/ \
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
      --cc 'linux-kernel@vger.kernel.org'
```

# TODO

## Submitting, final checks

- Feedback/RFC email
  - Is it normal to do [RFC] in fsdevel?
  - Send to Steve first?
  - Fill out commit messages
  - Fill out cover letter
  - Decide on subject. Should we not mention kernfs in any of this?
  - Actually go through testing again before submitting!
- Check for TODO items

## Non-coccinelle changes

- Try removing a few `debugfs_node_dentry` calls. I think they are only used for `%pd2` printf'ing and fetching a parent.
  - Consider a `->d_parent` -> new helper `debugfs_node_parent` and add to Coccinelle as well

## Coccinelle

- Clean up script. Pick either the old script or test the new script and see if that works.
- Don't hard code all of the debugfs functions. They should be found with the regex. We might just need the macros, but even then the regex should catch those.

- Investigate wrapper functions not getting transformed in `drivers/cxl/cxlmem.h` and `drivers/cxl/mem.c`
- `scmi_raw_mode_init` has declaration arg type changed, but not header prototype
- Pretty simple case not getting handled: `struct dentry *direct = blah->foo;` where `foo` was just migrated from dentry to debugfs_node. `direct` remains `dentry`


- Inversion idea from slide 195 here: <https://www.lrz.de/services/compute/courses/x_lecturenotes/hspc1w19.pdf>
  1. Find all declarations of type `struct dentry *`, record their position (maybe record if they are a field or not?)
  2. See if any of these are used in our debugfs-like functions (including wrappers)
  3. Change the types of any of the declarations that matched in function usage. We use the identifier/position from the first rule, and we just "depend on" the second rule
  4. We can also do our wrapper rewrites and stuff, easy peasy
     - Ensure we don't overconstrain rewriting wrappers as depending on matching a dentry.
     - Could do multiple passes. I think rewriting wrappers in the first pass
     - I think we can rewrite return values with a dedicated rule, and function args can be handled like other declarations. Then we don't need to specially rewrite wrappers

- `sound/soc/soc-pcm.c` isn't working (only file I think). It interesting because there is no dentry declaration in the actual file (but there is debugfs usage)
  - (old TODO) `include/sound/soc.h` has a `struct dentry *debugfs_dpcm_root;` field that refuses to get matches. I think all the `#define`s in the file are screwing with Coccinelle, because it works when I move that struct to my test file.

- Make a `cocci-test` directory in this subdirectory with multiple headers and C files to try and repro issues I see

- Split up coccinelle file, primarily for ease of understanding, but also some other benefits
  - It would be simpler if we did a first pass of rewriting helper functions with "debugfs" in the name, and a second pass without using regexes. In the second pass we can match for any functions with `debugfs_node *` as a return type or argument instead of a regex

- Test more complex assignments like `hb->dbgfs.base_dir = debugfs_create_dir("heartbeat", accel_dev->debugfs_dir);` in test file

- Use this style for putting type on different line from function def (not pointer `*` position):

  ```
  static struct debugfs_node *
  create_buf_file_callback(const char *filename, ...
  ```

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

- Sometimes `include/linux/debugfs.h` gets caught up in changes
  - I had it pulled in once when I just ran against `drivers/scsi/lpfc/`
  - I cannot for the life of me get this ignored

- Manual stuff:
  - Revert include/linux/fs.h changes (maybe we can exclude this file in the cocci script)
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
