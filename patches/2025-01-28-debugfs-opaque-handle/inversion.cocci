@find_wrapper_ret@
identifier f =~ "debugfs|dbgfs";
type T = { struct dentry *, struct debugfs_node * };
idexpression T e;
@@

e = f(...)

@find_wrapper_args@
identifier f =~ "debugfs|dbgfs";
type T = { struct dentry *, struct debugfs_node * };
T arg;
@@

f(..., arg, ...)

@find_debugfs_functions@
identifier f = {
  debugfs_change_name,
  debugfs_create_atomic_t,
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

@@

f(...)

@all_functions@
identifier f = { find_debugfs_functions.f, find_wrapper_ret.f, find_wrapper_args.f };
@@

f(...)

//
// Standalone declarations
//
@find_dentry_decls@
identifier var;
position p;
@@

// N.B. Matches static globals too
struct dentry@p *var;

@find_decl_use@
identifier all_functions.f;
identifier find_dentry_decls.var;
@@

(
  var = f(...)
|
  f(..., var, ...)
)

@change_decl_types depends on find_decl_use type@
position p = { find_dentry_decls.p };
@@

struct
-dentry@p
+debugfs_node

//
// Struct fields
//
@find_dentry_struct_decls@
identifier var, struct_name;
position p;
@@

struct struct_name {
       ...
       struct dentry@p *var;
       ...
};

@find_struct_use@
identifier all_functions.f;
identifier find_dentry_struct_decls.var;
expression E;
@@

(
  E.var = f(...)
|
  E->var = f(...)
|
  f(..., E->var, ...)
|
  f(..., E.var, ...)
)

@change_struct_decl_types depends on find_struct_use type@
position p = { find_dentry_struct_decls.p };
@@

struct
-dentry@p
+debugfs_node

//
// Function args
//
@@
identifier var, fn;
identifier all_functions.f;
@@

fn(...,
  struct
- dentry
+ debugfs_node
  *var, ...)
{
  ...
(
  var = f(...)
|
  f(..., var, ...)
)
  ...
}

//
// Function return types
//
@exists@
identifier f;
idexpression struct debugfs_node *e;
@@

struct
- dentry
+ debugfs_node
 *f(...)
{
  ...
  return e;
  ...
}