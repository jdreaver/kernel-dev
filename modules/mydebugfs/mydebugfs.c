// Modifies the default printk format to include the module name and function name
#define pr_fmt(fmt) KBUILD_MODNAME ":%s:%d: " fmt, __func__, __LINE__

#include <linux/debugfs.h>
#include <linux/fs.h>
#include <linux/module.h>
#include <linux/kernel.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("David Reaver");
MODULE_DESCRIPTION("An in-memory debugfs filesystem example.");

static struct dentry *mydebugfs_root;
static int counter = 0;
static bool mybool = false;

static ssize_t mydebugfs_read_counter(struct file *filp, char __user *buffer, size_t len, loff_t *offset)
{
	// Only allow reading from the beginning of the file
	if (*offset)
		return 0;

	// Write the value of mybool to the buffer
	char buf[16];
	int count = snprintf(buf, sizeof(buf), "%d\n", counter);
	if (count < 0 || count >= len)
		return -EINVAL;

	if (copy_to_user(buffer, buf, count))
		return -EFAULT;

	// Increment the counter
	counter++;

	*offset += count;
	return count;
}

static ssize_t mydebugfs_write_counter(struct file *filp, const char __user *buffer, size_t len, loff_t *offset)
{
	char buf[16];
	if (len >= sizeof(buf))
		return -EINVAL;

	if (copy_from_user(buf, buffer, len))
		return -EFAULT;

	buf[len] = '\0';
	int new_value;
	if (kstrtoint(buf, 10, &new_value))
		return -EINVAL;

	counter = new_value;
	return len;
}

static struct debugfs_short_fops mydebugfs_counter_ops = {
	.read = mydebugfs_read_counter,
	.write = mydebugfs_write_counter,
};

static int mydebugfs_init(void)
{
	pr_info("Registered mydebugfs\n");

	mydebugfs_root = debugfs_create_dir("mydebugfs", NULL);
	if (!mydebugfs_root) {
		pr_err("Failed to create mydebugfs directory\n");
		return -ENOMEM;
	}

	debugfs_create_file("mycounter", 0644, mydebugfs_root, NULL, &mydebugfs_counter_ops);
	debugfs_create_bool("mybool", 0644, mydebugfs_root, &mybool);

	return 0;
}

static void __exit mydebugfs_exit(void)
{
	debugfs_remove_recursive(mydebugfs_root);
	pr_info("Unregistered mydebugfs\n");
}

module_init(mydebugfs_init);
module_exit(mydebugfs_exit);
