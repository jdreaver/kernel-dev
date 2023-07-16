#include <linux/module.h>     /* Needed by all modules */
#include <linux/kernel.h>     /* Needed for KERN_INFO */
#include <linux/init.h>       /* Needed for the macros */

MODULE_LICENSE("GPL");
MODULE_AUTHOR("David Reaver");
MODULE_DESCRIPTION("A simple Hello world LKM!");
MODULE_VERSION("0.1");

static int __init hello_start(void)
{
	pr_info("Loading hello module...\n");
	pr_info("Hello world!\n");
	return 0;
}

static void __exit hello_end(void)
{
	pr_info("Goodbye.\n");
}

module_init(hello_start);
module_exit(hello_end);
