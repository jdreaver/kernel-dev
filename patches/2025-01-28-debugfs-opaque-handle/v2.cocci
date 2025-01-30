virtual patch


@vars_to_rewrite@
identifier f = {
  debugfs_create_dir,
  debugfs_create_file
};
identifier var;
identifier E;
@@

(
  var = f(...)
|
  f(..., var, ...)
)

@rewrite_decls@
identifier vars_to_rewrite.var;
@@

(
-struct dentry *var;
+struct debugfs_node *var;
|
-static struct dentry *var;
+static struct debugfs_node *var;
)

@fields_to_rewrite@
identifier f = {
  debugfs_create_dir,
  debugfs_create_file
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

// @debugfs_func_calls@
// position p;
// @@

// (
//   debugfs_create_dir(...)@p
// |
//   debugfs_create_file(...)@p
// |
//   my_debugfs_helper(...)@p
// )

// @vars_to_rewrite@
// position debugfs_func_calls.p;
// identifier var;
// @@

// (
//   var = f(...)@p;
// |
//   f(..., var, ...)@p;
// )

// @change_decl_types depends on vars_to_rewrite@
// identifier vars_to_rewrite.var;
// @@

// (
// -struct dentry *var;
// +struct debugfs_node *var;
// |
// -static struct dentry *var;
// +static struct debugfs_node *var;
// )


// @depends on debugfs_func_calls@
// identifier var;
// identifier df, f;
// type T;
// position debugfs_func_calls.p;
// @@

// (
// -struct dentry *var;
// +struct debugfs_node *var;
// |
// -static struct dentry *var;
// +static struct debugfs_node *var;
// )

// ...

// (
//   var = f(...)@p;
// |
//   f(..., var, ...)@p;
// )
