// Modifies the default printk format to include the module name and function name
#define pr_fmt(fmt) KBUILD_MODNAME ":%s:%d: " fmt, __func__, __LINE__

#include <linux/kernfs.h>
#include <linux/module.h>
#include <linux/kernel.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("David Reaver");
MODULE_DESCRIPTION("A pseudo-filesystem with counters using kernfs.");

static int mymykernfs_init(void)
{
	pr_info("Registered mykernfs\n");
	return 0;
}

static void __exit mymykernfs_exit(void)
{
	pr_info("Unregistered mykernfs\n");
}

module_init(mymykernfs_init);
module_exit(mymykernfs_exit);
