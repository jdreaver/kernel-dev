// Modifies the default printk format to include the module name and function name
#define pr_fmt(fmt) KBUILD_MODNAME ":%s:%d: " fmt, __func__, __LINE__

#include <linux/cred.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/sched.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("David Reaver");
MODULE_DESCRIPTION("Show information for the current task, as well as all tasks");

static int show_current_task_info(void)
{
	if (likely(in_task())) {
		pr_info("Current task info:\n");
		pr_info("  name: %s\n", current->comm);
		pr_info("  pid: %d\n", current->pid);
		pr_info("  tgid: %d\n", current->tgid);
		pr_info("  uid: %d\n", from_kuid(&init_user_ns, current_uid()));
		pr_info("  gid: %d\n", from_kgid(&init_user_ns, current_gid()));
		pr_info("  state: %c\n", task_state_to_char(current));
		pr_info("  current: 0x%pK (0x%px)\n", current, current);
		pr_info("  stack start: 0x%pK (0x%px)\n", current->stack, current->stack);
	} else {
		pr_crit("Not in a task. This should never happen!\n");
		return -1;
	}

	return 0;
}

static int show_all_tasks(void)
{
	pr_info("------------------------------------------------------------------------------------------\n");
	pr_info("    TGID     PID         current           stack-start         Thread Name     MT? # thrds\n");
	pr_info("------------------------------------------------------------------------------------------\n");

	struct task_struct *p, *t;

	rcu_read_lock();
	for_each_process_thread(p, t) {
		pr_info("  %6d  %6d  0x%pK 0x%pK %s  %c  %d\n",
			p->tgid, t->pid, t, t->stack, t->comm, task_state_to_char(t), t->signal->nr_threads);
	}
	rcu_read_unlock();

	return 0;
}

static int __init show_taskinfo_init(void)
{
	pr_info("module loaded\n");

	int result = show_current_task_info();
	if (result != 0)
	{
		pr_err("show_current_task_info failed\n");
		return result;
	}

	result = show_all_tasks();
	if (result != 0)
	{
		pr_err("show_all_tasks failed\n");
		return result;
	}

	return 0;
}

static void __exit show_taskinfo_exit(void)
{
	pr_info("Goodbye, Kernel!\n");
}

module_init(show_taskinfo_init);
module_exit(show_taskinfo_exit);
