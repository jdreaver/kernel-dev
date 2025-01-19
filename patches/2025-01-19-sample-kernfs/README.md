# Simple pseudo-filesystem sample build on top of `kernfs`

I'm working in my own `linux` tree in a branch called `davidreaver/sample-kernfs` and is located at <https://github.com/jdreaver/linux/tree/davidreaver/sample-kernfs> (diff URL: <https://github.com/jdreaver/linux/compare/master...jdreaver:linux:davidreaver/sample-kernfs>). I'm storing patches in this directory with:

```sh
cd ~/git/kernel-dev/linux
git switch davidreaver/sample-kernfs
git format-patch master...HEAD -o ../patches/2025-01-19-sample-kernfs/
```

## TODO

- Fix TODOs in counter file (memory management, locks, etc)
- Allow adding sub-directories with auto-populated `counter` file

  ```diff
  diff --git a/samples/kernfs/sample_kernfs.c b/samples/kernfs/sample_kernfs.c
  index 55d2513d6757..c42fd55601dd 100644
  --- a/samples/kernfs/sample_kernfs.c
  +++ b/samples/kernfs/sample_kernfs.c
  @@ -16,6 +16,23 @@

   static struct kernfs_root *sample_kernfs_root;

  +static int sample_kernfs_mkdir(struct kernfs_node *parent_kn, const char *name, umode_t mode)
  +{
  +       pr_info("Creating directory %s\n", name);
  +       return 0;
  +}
  +
  +static int sample_kernfs_rmdir(struct kernfs_node *kn)
  +{
  +       pr_info("Removing directory %s\n", kn->name);
  +       return 0;
  +}
  +
  +static struct kernfs_syscall_ops sample_kernfs_kf_syscall_ops = {
  +       .mkdir                  = sample_kernfs_mkdir,
  +       .rmdir                  = sample_kernfs_rmdir,
  +};
  +
   static int sample_kernfs_get_tree(struct fs_context *fc)
   {
          return kernfs_get_tree(fc);
  @@ -48,6 +65,6 @@ static struct file_system_type sample_kernfs_fs_type = {

   static int __init sample_kernfs_init(void)
   {
  -       sample_kernfs_root = kernfs_create_root(NULL, 0, NULL);
  +       sample_kernfs_root = kernfs_create_root(&sample_kernfs_kf_syscall_ops, 0, NULL);
          if (IS_ERR(sample_kernfs_root))
                  return PTR_ERR(sample_kernfs_root);
  ```

- Implement `sums` file
- In cover letter, mention how patches are split up (to demonstrate the "steps" of building a pseudo-filesystem on top of `kernfs`, where each step adds a feature).
- Either add documentation for `kernfs` in this patch series or mention that I want to add documentation.

## Cover letter (WIP)

This patch series creates a pseudo-filesystem built on top of kernfs in
samples/kernfs/.
