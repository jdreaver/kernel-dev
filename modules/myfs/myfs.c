// Modifies the default printk format to include the module name and function name
#define pr_fmt(fmt) KBUILD_MODNAME ":%s:%d: " fmt, __func__, __LINE__

#include <linux/xattr.h>
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

// myfs_file_data is stored in a struct file's private_data field to hold data
// written to the file.
struct myfs_file_data {
    char *data;
    size_t size;
};

static struct myfs_file_data *myfs_file_data_alloc(void)
{
	return kzalloc(sizeof(struct myfs_file_data), GFP_KERNEL);
}

static void myfs_file_data_alloc_buffer(struct myfs_file_data *data, size_t size)
{
	data->data = kmalloc(size, GFP_KERNEL);
	data->size = size;
}

static void myfs_file_data_realloc_buffer(struct myfs_file_data *data, size_t new_size)
{
	data->data = krealloc(data->data, new_size, GFP_KERNEL);
	data->size = new_size;
}

static void myfs_file_data_free(struct myfs_file_data *data)
{
	kfree(data->data);
	kfree(data);
}

// Read the internal file data buffer into the given user buffer.
static ssize_t myfs_read_file(struct file *file, char __user *buf,
				 size_t count, loff_t *ppos)
{
	pr_info("Reading file (inode = %zu)\n", file->f_inode->i_ino);

	struct myfs_file_data *file_data = file->private_data;
	if (!file_data) {
		pr_err("No file->private_data in file\n");
		return -EIO;
	}

	pr_info("Private data located at %p\n", file_data);
	pr_info("Reading file data, *ppos = %lld, file_data->size = %zu\n", *ppos, file_data->size);
	if (*ppos >= file_data->size) {
		pr_info("EOF\n");
		return 0; // EOF
	}

	size_t remaining = file_data->size - *ppos;
	if (count > remaining)
		count = remaining;

	if (copy_to_user(buf, file_data->data + *ppos, count))
		return -EFAULT;

	*ppos += count;

	pr_info("Read %zu bytes from file\n", count);
	return count;
}

// Write the given data to the internal file data buffer, resizing if necessary.
static ssize_t myfs_write_file(struct file *file, const char __user *buf,
				   size_t count, loff_t *ppos)
{

	struct myfs_file_data *file_data = file->private_data;
	if (!file_data) {
		pr_err("No file->private_data in file\n");
		return -EIO;
	}

	// Allocate memory for the file data, if necessary
	if (!file_data->data) {
		myfs_file_data_alloc_buffer(file_data, count);
		if (!file_data->data)
			return -ENOMEM;
	} else if (*ppos + count > file_data->size) {
		// Resize file_data->data to accommodate more data
		myfs_file_data_realloc_buffer(file_data, *ppos + count);
		if (!file_data->data)
			return -ENOMEM;
	}

	if (copy_from_user(file_data->data + *ppos, buf, count))
		return -EFAULT;

	*ppos += count;

	pr_info("Wrote %zu bytes to file (inode = %zu)\n", count, file->f_inode->i_ino);
	pr_info("Private data located at %p\n", file_data);
	pr_info("File data: %s (%zu bytes)\n", file_data->data, file_data->size);
	return count;
}

static int myfs_file_open(struct inode *inode, struct file *file)
{
	// Allocate some memory for the file and store a pointer to it in the
	// inode.
	pr_info("Opening file (inode = %lu)\n", inode->i_ino);
	if (!inode->i_private) {
		pr_info("Allocating file data\n");
		inode->i_private = myfs_file_data_alloc();
		pr_info("Allocated private data at %p\n", inode->i_private);
		if (!inode->i_private)
			return -ENOMEM;
	}

	// Associate the file's private_data with the inode's private data.
	file->private_data = inode->i_private;

	return 0;
}

static const struct file_operations myfs_file_operations = {
	.read	= myfs_read_file,
	.write	= myfs_write_file,
	.open	= myfs_file_open,
	.llseek	= noop_llseek,
};

static const struct inode_operations myfs_file_inode_operations = {
	.setattr	= simple_setattr,
};

const struct inode_operations myfs_dir_inode_operations;

static struct inode *myfs_get_inode(struct super_block *sb, const struct inode *dir, umode_t mode, dev_t dev)
{
	struct inode *inode = new_inode(sb);
	if (!inode)
		return NULL;

	inode->i_ino = get_next_ino();
	inode->i_sb = sb;
	inode_init_owner(&nop_mnt_idmap, inode, dir, mode);
	simple_inode_init_ts(inode);

	switch (mode & S_IFMT) {
	case S_IFREG:
		pr_info("Creating file inode\n");
		inode->i_op = &myfs_file_inode_operations;
		inode->i_fop = &myfs_file_operations;
		break;
	case S_IFDIR:
		pr_info("Creating directory inode\n");
		inode->i_op = &myfs_dir_inode_operations;
		inode->i_fop = &simple_dir_operations;
		break;
	default:
		pr_err("TODO: Implement other inode types\n");
		break;
	}
	pr_info("Created inode %lu\n", inode->i_ino);
	return inode;
}

static int myfs_mknod(struct mnt_idmap *idmap, struct inode *dir,
			   struct dentry *dentry, umode_t mode, dev_t dev)
{
	struct inode *inode = myfs_get_inode(dir->i_sb, dir, mode, dev);
	if (!inode)
		return -ENOSPC;
	d_instantiate(dentry, inode);
	// TODO: This dget shouldn't be here
	dget(dentry);
	inode_set_mtime_to_ts(dir, inode_set_ctime_current(dir));

	pr_info("Created %s inode %lu, nlink = %u\n", S_ISDIR(mode) ? "directory" : "file", inode->i_ino, inode->i_nlink);

	return 0;
}


static int myfs_create(struct mnt_idmap *idmap,
			    struct inode *dir, struct dentry *dentry,
			    umode_t mode, bool excl)
{
	return myfs_mknod(idmap, dir, dentry, mode | S_IFREG, 0);
}

static struct dentry *myfs_lookup(struct inode *dir, struct dentry *dentry, unsigned int flags)
{
	struct inode *inode = NULL;

	pr_info("Looking up file %s in directory %lu\n", dentry->d_name.name, dir->i_ino);

	/* Try to find an existing inode for the dentry */
	inode = dentry->d_inode;
	if (inode) {
		pr_info("Found existing inode %lu for %s\n", inode->i_ino, dentry->d_name.name);
		return NULL; // Entry already exists, nothing to do
	}

	/* If no inode exists, return a negative dentry */
	d_add(dentry, NULL);
	pr_info("No inode found for %s, returning negative dentry\n", dentry->d_name.name);
	return NULL;
}

const struct inode_operations myfs_dir_inode_operations = {
	.create		= myfs_create,
	.setattr	= simple_setattr,
	.lookup		= myfs_lookup,
	.permission	= generic_permission,
	.getattr	= simple_getattr,
};

static void myfs_evict_inode(struct inode *inode)
{
	struct myfs_file_data *file_data = inode->i_private;

	if (file_data) {
		myfs_file_data_free(file_data);
	}

	clear_inode(inode); // Clears VFS inode references
}

static void myfs_put_super(struct super_block *sb)
{
	// TODO: Free any resources associated with the superblock
	pr_info("myfs_put_super called\n");
}

static const struct super_operations myfs_super_operations = {
	.statfs = simple_statfs,
	.evict_inode = myfs_evict_inode,
	.put_super = myfs_put_super,
};

static const struct dentry_operations myfs_dentry_operations = {
	.d_delete = always_delete_dentry,
};

static int myfs_fill_super(struct super_block *sb, struct fs_context *fc)
{
	// TODO: Don't use simple_fill_super
	static const struct tree_descr files[] = {{""}};
	int err = simple_fill_super(sb, DEBUGFS_MAGIC, files);
	if (err)
		return err;

	// Just use normal pages for blocks since this is an in-memory
	// filesystem.
	sb->s_blocksize = PAGE_SIZE;
	sb->s_blocksize_bits = PAGE_SHIFT;

	sb->s_magic = MYFS_MAGIC;

	sb->s_op = &myfs_super_operations;
	sb->s_d_op = &myfs_dentry_operations;

	// TODO:
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
	.owner = THIS_MODULE,
	.name = "myfs",
	.init_fs_context = myfs_init_fs_context,
	// kill_anon_super is good for in-memory filesystems.
	.kill_sb = kill_anon_super,

	// N.B. mount is phased out in lieu of init_fs_context
	// .mount = myfs_mount,
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
