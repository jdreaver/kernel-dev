virtual patch

//
// Rewrite wrapper functions. These are functions that return a dentry or accept
// a dentry as an argument and look like they are related to debugfs.
//
@wrapper_function_returns depends on !(file in "fs/debugfs")@
identifier wfr =~ "debugfs|dbgfs";
@@

- struct dentry *
+ struct debugfs_node *
wfr(...) { ... }

@wrapper_function_args depends on !(file in "fs/debugfs")@
identifier wfa =~ "debugfs|dbgfs";
identifier arg;
@@

wfa(...,
- struct dentry *arg
+ struct debugfs_node *arg
  ,...)
{ ... }

// Collect all function calls
@function_calls@
identifier hf = {
  debugfs_change_name,
  debugfs_create_atomic_t,
  debugfs_create_automount,
  debugfs_create_bool,
  debugfs_create_devm_seqfile,
  debugfs_create_dir,
  debugfs_create_file,
  debugfs_create_file_aux,
  debugfs_create_file_aux_num,
  debugfs_create_file_full,
  debugfs_create_file_short,
  debugfs_create_file_size,
  debugfs_create_file_unsafe,
  debugfs_create_regset32,
  debugfs_create_size,
  debugfs_create_str,
  debugfs_create_symlink,
  debugfs_create_u16,
  debugfs_create_u32,
  debugfs_create_u32_array,
  debugfs_create_u64,
  debugfs_create_u8,
  debugfs_create_ulong,
  debugfs_create_x16,
  debugfs_create_x32,
  debugfs_create_x64,
  debugfs_create_x8,
  debugfs_lookup,
  debugfs_lookup_and_remove,
  debugfs_node_get,
  debugfs_node_path_raw,
  debugfs_node_put,
  debugfs_real_fops,
  debugfs_remove,
  debugfs_remove_recursive
};
identifier wrapper_function_returns.wfr;
identifier wrapper_function_args.wfa;
identifier f;
@@

(
  hf@f(...)
|
  wfr@f(...)
|
  wfa@f(...)
)

@decls_need_rewrite@
identifier function_calls.f;
idexpression struct dentry *var;
identifier var2;
identifier f2;
@@

(
  var@var2 = f@f2(...)
|
  f@f2(..., var@var2, ...)
)

@rewrite_decls@
identifier decls_need_rewrite.var2, decls_need_rewrite.f2;
identifier f;
@@

(
-  struct dentry *var2;
++ struct debugfs_node *var2;
|
-  static struct dentry *var2;
++ static struct debugfs_node *var2;
|
-  struct dentry *var2
+  struct debugfs_node *var2
= NULL;
|
-  struct dentry *var2
+  struct debugfs_node *var2
= f2(...);
)

@rewrite_function_arg_decls@
identifier decls_need_rewrite.var2, decls_need_rewrite.f2;
identifier f;
@@

f(...,
- struct dentry *var2,
+ struct debugfs_node *var2,
 ...) {...}

//
// Structs
//
@fields_need_rewrite@
identifier function_calls.f;
identifier var;
expression E;
@@

(
  E->var = f(...)
|
  E.var = f(...)
|
  f(..., E->var, ...)
|
  f(..., E.var, ...)
)

@rewrite_fields@
identifier fields_need_rewrite.var;
identifier struct_name;
@@

struct struct_name {
    ...
-   struct dentry *var;
+   struct debugfs_node *var;
    ...
};

//
// Rewrite declarations and fields that are dentries with names that very
// strongly imply they are for debugfs. This is necessary because sometimes
// Coccinelle doesn't go into all headers/structs.
//

@obvious_debugfs_decls depends on !(file in "fs/debugfs")@
identifier var =~ "debugfs|dbgfs|^debug_dir$|^debug_root$|^dbg_dir$";
@@

(
-  struct dentry *var;
++ struct debugfs_node *var;
|
-  static struct dentry *var;
++ static struct debugfs_node *var;
|
-  struct dentry *var
+  struct debugfs_node *var
= NULL;
)

@obvious_debugfs_fields depends on !(file in "fs/debugfs")@
identifier var =~ "debugfs|dbgfs|^debug_dir$|^debug_root$|^dbg_dir$";
identifier struct_name;
@@

struct struct_name {
    ...
-   struct dentry *var;
+   struct debugfs_node *var;
    ...
};

@obvious_debugfs_field_arrays depends on !(file in "fs/debugfs")@
identifier var =~ "debugfs|dbgfs|^debug_dir$|^debug_root$|^dbg_dir$";
identifier struct_name;
@@

struct struct_name {
    ...
-   struct dentry *var
+   struct debugfs_node *var
    [...];
    ...
};

// Replace d_inode with debugfs_node_inode
@@
idexpression struct debugfs_node *e;
@@

-d_inode(e)
+debugfs_node_inode(e)

// Rewrite return types of helper functions that return a debugfs_node now.
@@
identifier f;
idexpression struct debugfs_node *e;
@@

(
-static struct dentry *
+static struct debugfs_node *
  f(...) {
    ...
    return e;
    ...
  }
|
-struct dentry *
+struct debugfs_node *
  f(...) {
    ...
    return e;
    ...
  }
)

// Transform various helper functions
//
// TODO: This is way too wide, and depending on match_assign/match_usage is
// buggy. Restrict this a ton.
//
// @transform_helpers depends on match_assign || match_usage@
// identifier var, E;
// @@
//
// (
// // Replace dput
// - dput(var)
// + debugfs_node_put(var)
// |
// - dput(E->var)
// + debugfs_node_put(E->var)
// |
// // Replace dget
// - dget(var)
// + debugfs_node_get(var)
// |
// - dget(E->var)
// + debugfs_node_get(E->var)
// |
// // Replace dentry_path_raw
// - dentry_path_raw(var,
// + debugfs_node_path_raw(var,
//    ...)
// |
// - dentry_path_raw(E->var,
// + debugfs_node_path_raw(E->var,
//    ...)
// )
