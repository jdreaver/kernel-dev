// Modifies the default printk format to include the module name and function name
#define pr_fmt(fmt) KBUILD_MODNAME ":%s:%d: " fmt, __func__, __LINE__

#include <linux/module.h>
#include <linux/kernel.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("David Reaver");
MODULE_DESCRIPTION("An in-memory debugfs filesystem example.");

static int __init mydebugfs_init(void)
{
	pr_info("Registered mydebugfs\n");
	return 0;
}

static void __exit mydebugfs_exit(void)
{
	pr_info("Unregistered mydebugfs\n");
}

module_init(mydebugfs_init);
module_exit(mydebugfs_exit);
