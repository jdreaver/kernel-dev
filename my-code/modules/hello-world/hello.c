#include <linux/module.h>
#include <linux/kernel.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Your Name");
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
