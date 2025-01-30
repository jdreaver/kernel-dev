# Migrate `debugfs` to use `kernfs` under the hood

Related: [2025-01-19-sample-kernfs](../2025-01-19-sample-kernfs) and [2025-01-22-port-tracefs-kernfs](../2025-01-22-port-tracefs-kernfs).

Storing patches in this directory with:

```bash
git format-patch master...HEAD \
      --base=origin/master \
      -o ../patches/2025-01-28-debugfs-opaque-handle/ \
      --cover-letter \
      --description-file=../patches/2025-01-28-debugfs-opaque-handle/cover-letter-description.txt \
      --rfc \
      --to 'Greg Kroah-Hartman <gregkh@linuxfoundation.org>' \
      --to 'Rafael J. Wysocki <rafael@kernel.org>' \
      --to 'Danilo Krummrich <dakr@kernel.org>' \
      --cc 'Steven Rostedt <rostedt@goodmis.org>' \
      --cc 'Christian Brauner <brauner@kernel.org>' \
      --cc 'linux-fsdevel@vger.kernel.org' \
      --cc 'linux-kernel@vger.kernel.org'
```

# TODO

- Figure out `git format-patch` command to get subject into cover letter
- Some stuff isn't getting hit like in `arch/s390/include/asm/debug.h`. The `dentry` fields in a struct have `debugfs` in the name; clearly they should be part of this, but spatch probably can't figure out that is the right thing to include. Either debug the include or add a rule to have `dentry` vars with `debugfs` in the name get included.
- Script isn't doing enough:
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

## All debugfs API functions (from debugfs.hs)

List of names (in case we want to use this in coccinelle):

```
struct debugfs_node *debugfs_lookup(const char *name, struct debugfs_node *parent);

char *debugfs_node_path_raw(struct debugfs_node *node, char *buf, size_t buflen);

struct debugfs_node *debugfs_node_get(struct debugfs_node *node);
void debugfs_node_put(struct debugfs_node *node);

struct debugfs_node *debugfs_create_file_full(const char *name, umode_t mode,
					struct debugfs_node *parent, void *data,
					const void *aux,
					const struct file_operations *fops);
struct debugfs_node *debugfs_create_file_short(const char *name, umode_t mode,
					 struct debugfs_node *parent, void *data,
					 const void *aux,
					 const struct debugfs_short_fops *fops);

#define debugfs_create_file(name, mode, parent, data, fops)			\
	_Generic(fops,								\
		 const struct file_operations *: debugfs_create_file_full,	\
		 const struct debugfs_short_fops *: debugfs_create_file_short,	\
		 struct file_operations *: debugfs_create_file_full,		\
		 struct debugfs_short_fops *: debugfs_create_file_short)	\
		(name, mode, parent, data, NULL, fops)

#define debugfs_create_file_aux(name, mode, parent, data, aux, fops)		\
	_Generic(fops,								\
		 const struct file_operations *: debugfs_create_file_full,	\
		 const struct debugfs_short_fops *: debugfs_create_file_short,	\
		 struct file_operations *: debugfs_create_file_full,		\
		 struct debugfs_short_fops *: debugfs_create_file_short)	\
		(name, mode, parent, data, aux, fops)

struct debugfs_node *debugfs_create_file_unsafe(const char *name, umode_t mode,
				   struct debugfs_node *parent, void *data,
				   const struct file_operations *fops);

void debugfs_create_file_size(const char *name, umode_t mode,
			      struct debugfs_node *parent, void *data,
			      const struct file_operations *fops,
			      loff_t file_size);

struct debugfs_node *debugfs_create_dir(const char *name, struct debugfs_node *parent);

struct debugfs_node *debugfs_create_symlink(const char *name, struct debugfs_node *parent,
				      const char *dest);

struct debugfs_node *debugfs_create_automount(const char *name,
					struct debugfs_node *parent,
					debugfs_automount_t f,
					void *data);

void debugfs_remove(struct debugfs_node *debugfs_node);
#define debugfs_remove_recursive debugfs_remove

void debugfs_lookup_and_remove(const char *name, struct debugfs_node *parent);

const struct file_operations *debugfs_real_fops(const struct file *filp);
const void *debugfs_get_aux(const struct file *file);

int debugfs_file_get(struct debugfs_node *debugfs_node);
void debugfs_file_put(struct debugfs_node *debugfs_node);

ssize_t debugfs_attr_read(struct file *file, char __user *buf,
			size_t len, loff_t *ppos);
ssize_t debugfs_attr_write(struct file *file, const char __user *buf,
			size_t len, loff_t *ppos);
ssize_t debugfs_attr_write_signed(struct file *file, const char __user *buf,
debugfs_change_name
debugfs_create_u8
debugfs_create_u16
debugfs_create_u32
debugfs_create_u64
debugfs_create_ulong
debugfs_create_x8
debugfs_create_x16
debugfs_create_x32
debugfs_create_x64
debugfs_create_size
debugfs_create_atomic_t(const char *name, umode_t mode,
debugfs_create_bool(const char *name, umode_t mode, struct debugfs_node *parent,
debugfs_create_str
debugfs_node
debugfs_create_regset32
debugfs_print_regs32
debugfs_create_u32_array
debugfs_create_devm_seqfile
debugfs_initialized
debugfs_read_file_bool
debugfs_write_file_bool
debugfs_read_file_str
debugfs_enter_cancellation
debugfs_leave_cancellation
debugfs_create_file_aux_num
debugfs_get_aux_num
```

Raw declarations:

```
struct debugfs_node *debugfs_lookup(const char *name, struct debugfs_node *parent);

char *debugfs_node_path_raw(struct debugfs_node *node, char *buf, size_t buflen);

struct debugfs_node *debugfs_node_get(struct debugfs_node *node);
void debugfs_node_put(struct debugfs_node *node);

struct debugfs_node *debugfs_create_file_full(const char *name, umode_t mode,
					struct debugfs_node *parent, void *data,
					const void *aux,
					const struct file_operations *fops);
struct debugfs_node *debugfs_create_file_short(const char *name, umode_t mode,
					 struct debugfs_node *parent, void *data,
					 const void *aux,
					 const struct debugfs_short_fops *fops);

#define debugfs_create_file(name, mode, parent, data, fops)			\
	_Generic(fops,								\
		 const struct file_operations *: debugfs_create_file_full,	\
		 const struct debugfs_short_fops *: debugfs_create_file_short,	\
		 struct file_operations *: debugfs_create_file_full,		\
		 struct debugfs_short_fops *: debugfs_create_file_short)	\
		(name, mode, parent, data, NULL, fops)

#define debugfs_create_file_aux(name, mode, parent, data, aux, fops)		\
	_Generic(fops,								\
		 const struct file_operations *: debugfs_create_file_full,	\
		 const struct debugfs_short_fops *: debugfs_create_file_short,	\
		 struct file_operations *: debugfs_create_file_full,		\
		 struct debugfs_short_fops *: debugfs_create_file_short)	\
		(name, mode, parent, data, aux, fops)

struct debugfs_node *debugfs_create_file_unsafe(const char *name, umode_t mode,
				   struct debugfs_node *parent, void *data,
				   const struct file_operations *fops);

void debugfs_create_file_size(const char *name, umode_t mode,
			      struct debugfs_node *parent, void *data,
			      const struct file_operations *fops,
			      loff_t file_size);

struct debugfs_node *debugfs_create_dir(const char *name, struct debugfs_node *parent);

struct debugfs_node *debugfs_create_symlink(const char *name, struct debugfs_node *parent,
				      const char *dest);

struct debugfs_node *debugfs_create_automount(const char *name,
					struct debugfs_node *parent,
					debugfs_automount_t f,
					void *data);

void debugfs_remove(struct debugfs_node *debugfs_node);
#define debugfs_remove_recursive debugfs_remove

void debugfs_lookup_and_remove(const char *name, struct debugfs_node *parent);

const struct file_operations *debugfs_real_fops(const struct file *filp);
const void *debugfs_get_aux(const struct file *file);

int debugfs_file_get(struct debugfs_node *debugfs_node);
void debugfs_file_put(struct debugfs_node *debugfs_node);

ssize_t debugfs_attr_read(struct file *file, char __user *buf,
			size_t len, loff_t *ppos);
ssize_t debugfs_attr_write(struct file *file, const char __user *buf,
			size_t len, loff_t *ppos);
ssize_t debugfs_attr_write_signed(struct file *file, const char __user *buf,
			size_t len, loff_t *ppos);

int debugfs_change_name(struct debugfs_node *dentry, const char *fmt, ...) __printf(2, 3);

void debugfs_create_u8(const char *name, umode_t mode, struct debugfs_node *parent,
		       u8 *value);
void debugfs_create_u16(const char *name, umode_t mode, struct debugfs_node *parent,
			u16 *value);
void debugfs_create_u32(const char *name, umode_t mode, struct debugfs_node *parent,
			u32 *value);
void debugfs_create_u64(const char *name, umode_t mode, struct debugfs_node *parent,
			u64 *value);
void debugfs_create_ulong(const char *name, umode_t mode, struct debugfs_node *parent,
			  unsigned long *value);
void debugfs_create_x8(const char *name, umode_t mode, struct debugfs_node *parent,
		       u8 *value);
void debugfs_create_x16(const char *name, umode_t mode, struct debugfs_node *parent,
			u16 *value);
void debugfs_create_x32(const char *name, umode_t mode, struct debugfs_node *parent,
			u32 *value);
void debugfs_create_x64(const char *name, umode_t mode, struct debugfs_node *parent,
			u64 *value);
void debugfs_create_size_t(const char *name, umode_t mode,
			   struct debugfs_node *parent, size_t *value);
void debugfs_create_atomic_t(const char *name, umode_t mode,
			     struct debugfs_node *parent, atomic_t *value);
void debugfs_create_bool(const char *name, umode_t mode, struct debugfs_node *parent,
			 bool *value);
void debugfs_create_str(const char *name, umode_t mode,
			struct debugfs_node *parent, char **value);

struct debugfs_node *debugfs_create_blob(const char *name, umode_t mode,
				  struct debugfs_node *parent,
				  struct debugfs_blob_wrapper *blob);

void debugfs_create_regset32(const char *name, umode_t mode,
			     struct debugfs_node *parent,
			     struct debugfs_regset32 *regset);

void debugfs_print_regs32(struct seq_file *s, const struct debugfs_reg32 *regs,
			  int nregs, void __iomem *base, char *prefix);

void debugfs_create_u32_array(const char *name, umode_t mode,
			      struct debugfs_node *parent,
			      struct debugfs_u32_array *array);

void debugfs_create_devm_seqfile(struct device *dev, const char *name,
				 struct debugfs_node *parent,
				 int (*read_fn)(struct seq_file *s, void *data));

bool debugfs_initialized(void);

ssize_t debugfs_read_file_bool(struct file *file, char __user *user_buf,
			       size_t count, loff_t *ppos);

ssize_t debugfs_write_file_bool(struct file *file, const char __user *user_buf,
				size_t count, loff_t *ppos);

ssize_t debugfs_read_file_str(struct file *file, char __user *user_buf,
			      size_t count, loff_t *ppos);

void __acquires(cancellation)
debugfs_enter_cancellation(struct file *file,
			   struct debugfs_cancellation *cancellation);
void __releases(cancellation)
debugfs_leave_cancellation(struct file *file,
			   struct debugfs_cancellation *cancellation);

#define debugfs_create_file_aux_num(name, mode, parent, data, n, fops) \
	debugfs_create_file_aux(name, mode, parent, data, \
				(void *)(unsigned long)n, fops)
#define debugfs_get_aux_num(f) (unsigned long)debugfs_get_aux(f)
```
