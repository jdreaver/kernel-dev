virtual patch

@vars_to_rewrite@
identifier f = {
  debugfs_create_dir,
  debugfs_create_file
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

@find_helper_functions@
identifier f = {
  my_debugfs_helper
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
