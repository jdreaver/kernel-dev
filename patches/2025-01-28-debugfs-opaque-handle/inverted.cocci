virtual patch

@decls_need_rewrite@
// TODO: DRY function list
identifier f = {
  debugfs_create_dir,
  debugfs_create_file
};
idexpression struct dentry *var;
identifier var2;
@@

(
  var@var2 = f(...)
|
  f(..., var@var2, ...)
)

@rewrite_decls depends on decls_need_rewrite@
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
identifier f = {
  debugfs_create_dir,
  debugfs_create_file
};
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
