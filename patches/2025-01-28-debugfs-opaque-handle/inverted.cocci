virtual patch

//
// Rewrite wrapper functions. These are functions that return a dentry and look
// like they are related to debugfs.
//
@wrapper_function_returns depends on !(file in "fs/debugfs")@
identifier wfr =~ "debugfs";
@@

- struct dentry *
+ struct debugfs_node *
wfr(...) { ... }

@wrapper_function_args depends on !(file in "fs/debugfs")@
identifier wfa =~ "debugfs";
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
@@

(
  var@var2 = f(...)
|
  f(..., var@var2, ...)
)

@rewrite_decls@
identifier decls_need_rewrite.var2;
@@

(
- struct dentry *var2;
+ struct debugfs_node *var2;
|
- static struct dentry *var2;
+ static struct debugfs_node *var2;
)

//
// Structs
//
@structs_with_dentry@
identifier S, var;
@@

struct S {
       ...
       struct dentry *var;
       ...
};

@fields_need_rewrite@
identifier function_calls.f;
identifier structs_with_dentry.S, structs_with_dentry.var;
idexpression struct S *sp;
idexpression struct S sv;
@@

(
  sp->var = f(...)
|
  sv.var = f(...)
|
  f(..., sp->var, ...)
|
  f(..., sv.var, ...)
)

@rewrite_fields depends on fields_need_rewrite@
//identifier fields_need_rewrite.S, fields_need_rewrite.var;
identifier structs_with_dentry.S, structs_with_dentry.var;
@@

struct S {
       ...
-      struct dentry *var;
+      struct debugfs_node *var;
       ...
};
