// Options: --all-includes

virtual patch

@@
identifier struct_name;
identifier var =~ ".*(dbg|debug).*";  // Match any variable with "dbg" or "debug" in its name
@@

(
- struct dentry *var;
+ struct debugfs_node *var;
|
struct struct_name {
    ...
-   struct dentry *var;
+   struct debugfs_node *var;
    ...
};
)
