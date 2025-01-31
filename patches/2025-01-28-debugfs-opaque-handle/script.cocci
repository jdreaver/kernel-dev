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

@find_dentry_vars@
identifier function_calls.f;
idexpression struct dentry *e;
identifier var;
identifier f2;
@@

(
  e@var = f@f2(...)
|
  f@f2(..., e@var, ...)
)

// find_decls and change_decl_types are separate so we properly handle static
// declarations as well as multi-declarations (e.g. struct dentry *a, *b, *c;).
// The "= NULL" and "= f2(...)" cases get thrown off when we combine them into
// one rule.
@find_decls@
identifier find_dentry_vars.var, find_dentry_vars.f2;
position p;
@@

(
  struct dentry@p *var;
|
  struct dentry@p *var = NULL;
|
  struct dentry@p *var = f2(...);
)

@change_decl_types type@
position find_decls.p;
@@

-struct dentry@p
+struct debugfs_node

@rewrite_function_arg_decls@
identifier find_dentry_vars.var;
identifier f;
@@

f(...,
- struct dentry *
+ struct debugfs_node *
  var,
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
-   struct dentry *
+   struct debugfs_node *
    var;
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
- struct dentry *
+ struct debugfs_node *
  var;
|
- struct dentry *
+ struct debugfs_node *
  var = NULL;
)

@obvious_debugfs_fields depends on !(file in "fs/debugfs")@
identifier var =~ "debugfs|dbgfs|^debug_dir$|^debug_root$|^dbg_dir$";
identifier struct_name;
@@

struct struct_name {
    ...
-   struct dentry *
+   struct debugfs_node *
    var;
    ...
};

@obvious_debugfs_field_arrays depends on !(file in "fs/debugfs")@
identifier var =~ "debugfs|dbgfs|^debug_dir$|^debug_root$|^dbg_dir$";
identifier struct_name;
@@

struct struct_name {
    ...
-   struct dentry *
+   struct debugfs_node *
    var [...];
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
