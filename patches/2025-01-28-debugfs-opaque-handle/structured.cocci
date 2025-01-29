// Options: --all-includes

virtual patch

// Match both direct assignments and field assignments
@match_assign@
expression E;
identifier var;
identifier fn =~ "^debugfs_";
@@

(
  var = fn(...)
|
  E->var = fn(...)
)

// Match both direct args and field args
@match_usage@
expression E;
identifier var;
identifier fn =~ "^debugfs_";
@@

(
  fn(..., var, ...)
|
  fn(..., E->var, ...)
)

// Transform declarations
@transform_decls depends on match_assign || match_usage@
identifier var;
identifier struct_name;
@@

// Global declarations
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
)

// Transform various helper functions
@transform_helpers depends on match_assign || match_usage@
identifier var, E;
@@

(
// Replace dput
- dput(var)
+ debugfs_node_put(var)
|
- dput(E->var)
+ debugfs_node_put(E->var)
|
// Replace dget
- dget(var)
+ debugfs_node_get(var)
|
- dget(E->var)
+ debugfs_node_get(E->var)
|
// Replace dentry_path_raw
- dentry_path_raw(var,
+ debugfs_node_path_raw(var,
   ...)
|
- dentry_path_raw(E->var,
+ debugfs_node_path_raw(E->var,
   ...)
)

//@depends on file in "lib/fault-inject.c"@

// Transform wrapper function args.
@@
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
@@
identifier fn =~ "debugfs";
@@

- struct dentry *
+ struct debugfs_node *
fn(...) { ... }
