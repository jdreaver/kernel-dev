// Options: --all-includes

virtual patch

// Match both direct assignments and field assignments to functions with
// "debugfs" in the name. Purposely casting a wide net to include wrapper
// functions that some modules imlpement, not just the debugfs.h functions.
@match_assign depends on !(file in "fs/debugfs/")@
expression E;
identifier var;
identifier fn =~ "debugfs";
@@

(
  var = fn(...)
|
  E->var = fn(...)
|
  E.var = fn(...)
)

// Transform declarations
@transform_assign depends on match_assign@
identifier match_assign.var;
identifier struct_name;
@@

// Declarations
(
- struct dentry *var;
+ struct debugfs_node *var;
|
- struct dentry *var
+ struct debugfs_node *var
= NULL;
|
- static struct dentry *var;
+ static struct debugfs_node *var;
|
// Struct field declarations
struct struct_name {
    ...
-   struct dentry *var;
+   struct debugfs_node *var;
    ...
};
)

// Match both direct args and field args
@match_usage depends on !(file in "fs/debugfs/")@
expression E;
identifier var;
identifier fn =~ "debugfs";
@@

(
  fn(..., var, ...)
|
  fn(..., E->var, ...)
|
  fn(..., E.var, ...)
)

// Transform declarations. It would be nice to DRY this with the above, but we
// can't easily reuse identifiers.var like that.
@transform_usage depends on match_usage@
identifier match_usage.var;
identifier struct_name;
@@

// Declarations
(
- struct dentry *var;
+ struct debugfs_node *var;
|
- struct dentry *var
+ struct debugfs_node *var
= NULL;
|
- static struct dentry *var;
+ static struct debugfs_node *var;
|
// Struct field declarations
struct struct_name {
    ...
-   struct dentry *var;
+   struct debugfs_node *var;
    ...
};
)

// Declaration and assignment in one
@depends on !(file in "fs/debugfs/")@
identifier var;
identifier fn =~ "debugfs";
@@

- struct dentry *var
+ struct debugfs_node *var
= fn(...);

// Variable declarations that are almost certainly supposed to be debugfs_node.
// Sometimes these are in headers that the other rules don't traverse because
// spatch misses some imports.
@depends on !(file in "fs/debugfs/")@
identifier var =~ "debugfs|^debug_dir$|^debug_root$";
identifier struct_name;
@@

// Declarations
(
- struct dentry *var;
+ struct debugfs_node *var;
|
- static struct dentry *var;
+ static struct debugfs_node *var;
|
// Struct field declarations
struct struct_name {
    ...
-   struct dentry *var;
+   struct debugfs_node *var;
    ...
};
|
struct struct_name {
    ...
    // Match arrays too
-   struct dentry *var
+   struct debugfs_node *var
    [...];
    ...
};
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

// Transform wrapper function args.
@depends on !(file in "fs/debugfs/")@
identifier arg;
identifier fn =~ "debugfs|create_setup_data_node|\
                  create_setup_data_nodes";
@@

fn(...,
- struct dentry *arg
+ struct debugfs_node *arg
  ,...)
{ ... }

// Transform wrapper function return types
@depends on !(file in "fs/debugfs/")@
identifier fn =~ "debugfs";
@@

- struct dentry *
+ struct debugfs_node *
fn(...) { ... }
