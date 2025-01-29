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
@transform depends on match_assign || match_usage@
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