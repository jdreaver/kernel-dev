// Modifies the default printk format to include the module name and function name
#define pr_fmt(fmt) KBUILD_MODNAME ":%s:%d: " fmt, __func__, __LINE__

#include <linux/fs.h>
#include <linux/fs_context.h>
#include <linux/module.h>
#include <linux/kernel.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("David Reaver");
MODULE_DESCRIPTION("A simple module example");

// It is important to have a magic number so VFS can use it for error checking
// and some type safety mechanisms.
#define MYFS_MAGIC 0x3a414e27

static const struct inode_operations myfs_inode_operations = {
};

const struct inode_operations myfs_dir_inode_operations = {
};

static struct inode *myfs_get_inode(struct super_block *sb, const struct inode *dir, umode_t mode, dev_t dev)
{
	struct inode *inode = new_inode(sb);
	if (!inode)
		return NULL;

	inode->i_ino = get_next_ino();
	inode->i_sb = sb;
	inode_init_owner(&nop_mnt_idmap, inode, dir, mode);

	struct timespec64 ts;
	ktime_get_real_ts64(&ts);
	inode_set_atime_to_ts(inode, ts);
	inode_set_mtime_to_ts(inode, ts);
	inode_set_ctime_to_ts(inode, ts);

	switch (mode & S_IFMT) {
	case S_IFREG:
		inode->i_op = &myfs_inode_operations;
		break;
	case S_IFDIR:
		inode->i_op = &myfs_dir_inode_operations;
		break;
	default:
		pr_err("TODO: Implement other inode types\n");
		break;
	}
	pr_info("Created inode %lu\n", inode->i_ino);
	return inode;
}

static const struct super_operations myfs_super_operations = {
};

static const struct dentry_operations myfs_dentry_operations = {
	.d_delete = always_delete_dentry,
};

static int myfs_fill_super(struct super_block *sb, struct fs_context *fc)
{
	// Just use normal pages for blocks since this is an in-memory
	// filesystem.
	sb->s_blocksize = PAGE_SIZE;
	sb->s_blocksize_bits = PAGE_SHIFT;

	sb->s_magic = MYFS_MAGIC;

	sb->s_op = &myfs_super_operations;
	sb->s_d_op = &myfs_dentry_operations;

	// TODO:
	// sb->s_op = &myfs_sops;
	// sb->s_time_gran = 1;

	// Allocate root inode
	// TODO: Locking here?
	struct inode *root_inode = myfs_get_inode(sb, NULL, S_IFDIR | 0755, 0);
	if (!root_inode)
		return -ENOMEM;

	sb->s_root = d_make_root(root_inode);
	if (!sb->s_root) {
		iput(root_inode);
		return -ENOMEM;
	}

	return 0;
}

static int myfs_get_tree(struct fs_context *fc)
{
	// For now, only allow one instance of the filesystem.
	return get_tree_single(fc, myfs_fill_super);
}

static const struct fs_context_operations myfs_fs_context_ops = {
	.get_tree = myfs_get_tree,
};

static int myfs_init_fs_context(struct fs_context *fc)
{
	fc->ops = &myfs_fs_context_ops;
	return 0;
}


static struct file_system_type myfs_type = {
	.name = "myfs",
	.init_fs_context = myfs_init_fs_context,
	.kill_sb = kill_anon_super,

	// N.B. mount is phased out in lieu of init_fs_context
	// .mount = myfs_mount,
	// kill_anon_super is good for in-memory filesystems.
};

static int __init myfs_init(void)
{
	int ret = register_filesystem(&myfs_type);
	if (ret != 0) {
		pr_err("Failed to register filesystem: %d\n", ret);
		return ret;
	}

	return 0;
}

static void __exit myfs_exit(void)
{
	unregister_filesystem(&myfs_type);
	pr_info("Unregistered myfs\n");
}

module_init(myfs_init);
module_exit(myfs_exit);
