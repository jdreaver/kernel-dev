// Modifies the default printk format to include the module name and function name
#define pr_fmt(fmt) KBUILD_MODNAME ":%s:%d: " fmt, __func__, __LINE__

#include <linux/module.h>
#include <linux/kernel.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("David Reaver");
MODULE_DESCRIPTION("A simple module example");

static int __init myfs_init(void)
{
	pr_info("Myfs, Kernel!\n");
	return 0;
}

static void __exit myfs_exit(void)
{
	pr_info("Goodbye, Kernel!\n");
}

module_init(myfs_init);
module_exit(myfs_exit);
