virtual patch

//
// Rewrite wrapper functions. These are functions that return a dentry
// or accept a dentry as an argument and look like they are related to
// debugfs.
//
@wrapper_function_returns depends on !(file in "fs/debugfs") && !(file in "include/linux/debugfs.h")@
identifier wfr =~ "debugfs|dbgfs";
type T = { struct dentry *, struct debugfs_node * };
idexpression T e;
@@

e = wfr(...)

@wrapper_function_args depends on !(file in "fs/debugfs") && !(file in "include/linux/debugfs.h")@
identifier wfa =~ "debugfs|dbgfs";
type T = { struct dentry *, struct debugfs_node * };
T arg;
@@

wfa(..., arg, ...)

// Rewrite rule is separate in case wrapper is not in the same file.
@rewrite_wrapper_returns depends on !(file in "fs/debugfs") && !(file in "include/linux/debugfs.h")@
identifier wfr =~ "debugfs|dbgfs";
@@

- struct dentry *
+ struct debugfs_node *
wfr(...) { ... }

// Rewrite rule is separate in case wrapper is not in the same file.
@rewrite_wrapper_args depends on !(file in "fs/debugfs") && !(file in "include/linux/debugfs.h")@
identifier wfa =~ "debugfs|dbgfs";
identifier arg;
@@

wfa(...,
- struct dentry
+ struct debugfs_node
  *arg
  ,...)
{ ... }

// Collect all function calls
@function_calls@
// This hard-coded list is separate from the wrapper regexes above so we don't
// go and mutate core debugfs functions on accident. Many of these purposely
// have dentry types in them.
identifier hf = {
  // Macros with debugfs_node. Coccinelle can't infer types for these.
  debugfs_create_file,
  debugfs_create_file_aux,
  debugfs_create_file_aux_num,
  debugfs_remove_recursive,

  // Actual functions
  debugfs_change_name,
  debugfs_create_atomic_t,
  debugfs_create_bool,
  debugfs_create_devm_seqfile,
  debugfs_create_dir,
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
  debugfs_remove
};
identifier wrapper_function_returns.wfr;
identifier wrapper_function_args.wfa;
// Exclude functions that might have been fuzzy matched that should
// "stay" with dentry.
identifier f != {
  debugfs_create_automount,
  debugfs_file_get,
  debugfs_file_put
};
@@

(
  hf@f(...)
|
  wfr@f(...)
|
  wfa@f(...)
)

// We need to separate cases for when a variable is in the return
// position vs a function arg. If we combine them, then we will miss
// cases where they both happen at the same time, e.g. x = f(y) where x
// and y are both dentries.
@find_dentry_return_vars@
identifier f = { function_calls.f };
idexpression struct dentry *e;
identifier var;
@@

e@var = f(...)

@find_dentry_arg_vars@
identifier f = { function_calls.f };
idexpression struct dentry *e;
identifier var;
@@

f(..., e@var, ...)

// find_decls and change_decl_types are separate so we properly handle
// static declarations as well as multi-declarations (e.g. struct dentry
// *a, *b, *c;). The "= NULL", "= f(...)", and "= E" cases get thrown
// off when we combine them into one rule.
@find_decls@
identifier var = { find_dentry_return_vars.var, find_dentry_arg_vars.var };
identifier f = { find_dentry_return_vars.f, find_dentry_arg_vars.f };
position p;
idexpression struct debugfs_node *E;
@@

(
  struct dentry@p *var;
|
  struct dentry@p *var = NULL;
|
  struct dentry@p *var = f(...);
|
  struct dentry@p *var = E;
)

@change_decls type@
position find_decls.p;
@@

-struct dentry@p
+struct debugfs_node

@find_function_arg_decls@
identifier var = { find_dentry_return_vars.var, find_dentry_arg_vars.var };
identifier f;
position p;
@@

f(..., struct dentry@p *var, ...) {...}

@change_function_arg_decls type@
position find_function_arg_decls.p;
@@

-struct dentry@p
+struct debugfs_node


//
// Struct fields
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

(
struct struct_name {
    ...
-   struct dentry *
+   struct debugfs_node *
    var;
    ...
};
|
struct {
    ...
-   struct dentry *
+   struct debugfs_node *
    var;
    ...
} struct_name;
)

//
// Rewrite declarations and fields that are dentries with names that
// very strongly imply they are for debugfs. This is necessary because
// sometimes Coccinelle doesn't go into all headers/structs.
//
@obvious_debugfs_decls depends on !(file in "fs/debugfs") && !(file in "include/linux/debugfs.h")@
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

@obvious_debugfs_fields depends on !(file in "fs/debugfs") && !(file in "include/linux/debugfs.h")@
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

@obvious_debugfs_field_arrays depends on !(file in "fs/debugfs") && !(file in "include/linux/debugfs.h")@
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

// Rewrite return types of helper functions that return a debugfs_node
// now.
@rewrite_helper_return_exp@
identifier f;
idexpression struct debugfs_node *e;
@@

-struct dentry *
+struct debugfs_node *
  f(...) {
    ...
    return e;
    ...
  }

@rewrite_helper_return_ret@
identifier fn;
identifier function_calls.f;
@@

struct
- dentry
+ debugfs_node
 *fn(...)
{
  ...
  return f(...);
  ...
}

//
// Add #define debugfs_node dentry if debugfs_node is used anywhere.
// This prevents implicit declarations.
//
@define_exists@
@@

#define debugfs_node dentry

@any_debugfs_node_usage type@
@@

struct debugfs_node

@depends on !define_exists and any_debugfs_node_usage@
@@

struct dentry;
+#define debugfs_node dentry

//
// Transform various helper functions
//
@@
idexpression struct debugfs_node *e;
@@

-d_inode(e)
+debugfs_node_inode(e)

@@
idexpression struct debugfs_node *e;
@@

-e->d_inode
+debugfs_node_inode(e)

@@
idexpression struct debugfs_node *e;
@@

-dput(e)
+debugfs_node_put(e)

@@
idexpression struct debugfs_node *e;
@@

-dget(e)
+debugfs_node_get(e)

@@
idexpression struct debugfs_node *e;
@@

- dentry_path_raw
+ debugfs_node_path_raw
  (e, ...);
