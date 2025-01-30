virtual patch

@find_helper_functions@
identifier f = {
  gpio_virtuser_create_debugfs_attrs
};
@@

f(...) {...}

@rewrite_helper_return_types@
identifier find_helper_functions.f;
@@

- struct dentry *
+ struct debugfs_node *
f(...) {...}

@rewrite_helper_args@
identifier arg;
identifier find_helper_functions.f;
@@

f(...,
- struct dentry *arg
+ struct debugfs_node *arg
  ,...)
{ ... }


@vars_to_rewrite@
identifier f = {
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
  debugfs_remove_recursive,

  // Helpers
  gpio_virtuser_create_debugfs_attrs
};
identifier var;
@@

(
  var = f(...)
|
  f(..., var, ...)
)

@rewrite_decls@
identifier vars_to_rewrite.var;
expression E;
@@

(
-struct dentry *var;
+struct debugfs_node *var;
|
-static struct dentry *var;
+static struct debugfs_node *var;
|
-struct dentry *var
+struct debugfs_node *var
= E;
)

@fields_to_rewrite@
identifier f = {
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
  debugfs_remove_recursive,

  // Helpers
  gpio_virtuser_create_debugfs_attrs
};
identifier var;
identifier E;
@@

(
  E->var = f(...)
|
  f(..., E->var, ...)
|
  E.var = f(...)
|
  f(..., E.var, ...)
)

@rewrite_structs@
identifier fields_to_rewrite.var;
identifier struct_name;
@@

struct struct_name {
  ...
- struct dentry *var;
+ struct debugfs_node *var;
  ...
};
