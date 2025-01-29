// Options: --all-includes

virtual patch

// Match both direct assignments and field assignments
@match_assign@
expression E;
identifier var;
@@

(
  var = debugfs_create_dir(...)
|
  E->var = debugfs_create_dir(...)
)

// Match both direct args and field args
@match_usage@
expression E1, E2;
identifier var;
@@

(
  debugfs_create_dir(E1, var)
|
  debugfs_create_dir(E1, E2->var)
)

// Transform declarations
@transform depends on match_assign || match_usage@
identifier var;  // Will match vars from either rule
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