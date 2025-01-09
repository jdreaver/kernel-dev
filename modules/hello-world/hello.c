// Modifies the default printk format to include the module name and function name
#define pr_fmt(fmt) KBUILD_MODNAME ":%s:%d: " fmt, __func__, __LINE__

#include <linux/module.h>
#include <linux/kernel.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("David Reaver");
MODULE_DESCRIPTION("A simple module example");

static int __init hello_init(void)
{
	pr_info("Hello, Kernel!\n");
	return 0;
}

static void __exit hello_exit(void)
{
	pr_info("Goodbye, Kernel!\n");
}

module_init(hello_init);
module_exit(hello_exit);
