// Options: --all-includes

virtual patch

@find_debugfs_func_call@
position p;
@@

(
  debugfs_create_dir(...)@p
|
  debugfs_create_file(...)@p
|
  my_debugfs_helper(...)@p
)

@depends on find_debugfs_func_call@
identifier f;
position find_debugfs_func_call.p;
@@

+/* Found function! */
f(...)@p


// @speed_up depends on !(file in "foo")@
// @@

// (
//   debugfs_create_dir(...);
// |
//   debugfs_create_file(...);
// |
//   my_debugfs_helper(...);
// )

// @find_debugfs_func_call depends on speed_up@
// //@find_debugfs_func_call@
// identifier f =~ "^debugfs_create_dir$|^debugfs_create_file$|^my_debugfs_helper$";
// @@

// f(...)

// @depends on find_debugfs_func_call@
// identifier find_debugfs_func_call.f;
// @@

// +/* Found function! */
// f


// @@
// identifier f =~ "debugfs|dbgfs|^debug_dir$|^debug_root$";
// @@

// +/* Found function call */
// f(...)

// @@
// identifier f =~ "debugfs|dbgfs|^debug_dir$|^debug_root$";
// @@

// +/* Found function declaration */
// f(...) { ... }


// Find dentry variable declarations that are pretty clearly for debugfs
// @depends on !(file in "fs/debugfs/")@
// type T = struct dentry;
// expression E;
// identifier var =~ "debugfs|dbgfs|^debug_dir$|^debug_root$";
// @@

// (
// - struct dentry *var;
// + struct debugfs_node *var;
// |
// - struct dentry *var
// + struct debugfs_node *var
// = E;
// |
// - static struct dentry *var;
// + static struct debugfs_node *var;
// )


// @@
// type T = struct dentry *;
// identifier var =~ "debugfs|dbgfs|^debug_dir$|^debug_root$";
// identifier v1, v2;
// //identifier list IL;
// @@

// (
// - struct dentry
// + struct debugfs_node
//   *var;
// |
// - struct dentry
// + struct debugfs_node
//   *var, *v1;
// |
// - struct dentry
// + struct debugfs_node
//   *v1, *var;
// )

// @@
// identifier var;
// @@

// -int var;
// ++double var;

// @match_int@
// identifier v;
// @@

// int v;

// @depends on match_int@
// identifier match_int.v;
// identifier o;
// @@

// (
// -int v, o;
// +double v, o;
// |
// -int o, v;
// +double o, v;
// )

// @match_assign@
// expression E;
// identifier var;
// identifier fn =~ "debugfs|dbgfs";
// @@

// fn(...)
