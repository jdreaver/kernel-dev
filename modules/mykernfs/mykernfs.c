// Modifies the default printk format to include the module name and function name
#define pr_fmt(fmt) KBUILD_MODNAME ":%s:%d: " fmt, __func__, __LINE__

#include <linux/fs.h>
#include <linux/fs_context.h>
#include <linux/kernfs.h>
#include <linux/module.h>
#include <linux/kernel.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("David Reaver");
MODULE_DESCRIPTION("A pseudo-filesystem with counters using kernfs.");

#define MYKERNFS_MAGIC 0x8d000ff0

static struct kernfs_root *mykernfs_root;
struct kernfs_node *mykernfs_root_kn;

static int mykernfs_get_tree(struct fs_context *fc)
{
	return kernfs_get_tree(fc);
}

static const struct fs_context_operations mykernfs_fs_context_ops = {
	.get_tree	= mykernfs_get_tree,
};

static int mykernfs_init_fs_context(struct fs_context *fc)
{
	struct kernfs_fs_context *kfc = kzalloc(sizeof(struct kernfs_fs_context), GFP_KERNEL);
	if (!kfc)
		return -ENOMEM;

	kfc->root = mykernfs_root;
	kfc->magic = MYKERNFS_MAGIC;
	fc->fs_private = kfc;
	fc->ops = &mykernfs_fs_context_ops;
	fc->global = true;
	return 0;
}

static void mykernfs_kill_sb(struct super_block *sb)
{
	kernfs_kill_sb(sb);
	// TODO: Free any resources allocated to the superblock, if any
}

static struct file_system_type mykernfs_fs_type = {
	.name			= "mykernfs",
	.init_fs_context	= mykernfs_init_fs_context,
	.kill_sb		= mykernfs_kill_sb,
	.fs_flags		= FS_USERNS_MOUNT,
};

static int mymykernfs_init(void)
{
	mykernfs_root = kernfs_create_root(NULL, 0, NULL);
	if (IS_ERR(mykernfs_root))
		return PTR_ERR(mykernfs_root);

	int err = register_filesystem(&mykernfs_fs_type);
	if (err) {
		kernfs_destroy_root(mykernfs_root);
		return err;
	}

	pr_info("Registered mykernfs\n");
	return 0;
}

static void __exit mymykernfs_exit(void)
{
	pr_info("Unregistered mykernfs\n");
}

module_init(mymykernfs_init);
module_exit(mymykernfs_exit);
