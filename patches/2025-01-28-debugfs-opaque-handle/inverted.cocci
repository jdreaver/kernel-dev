virtual patch

//
// Declarations
//
@dentry_decls@
identifier var;
@@

(
  struct dentry* var;
|
  static struct dentry* var;
)

@decls_need_rewrite@
// TODO: DRY function list
identifier f = {
  debugfs_create_dir,
  debugfs_create_file
};
identifier dentry_decls.var;
@@

(
  var = f(...)
|
  f(..., var, ...)
)

@rewrite_decls depends on decls_need_rewrite@
identifier dentry_decls.var;
@@

(
- struct dentry *var;
+ struct debugfs_node *var;
|
- static struct dentry *var;
+ static struct debugfs_node *var;
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
