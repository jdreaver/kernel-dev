#include <linux/debugfs.h>

#include "test.h"

static struct dentry *test;
static struct dentry *debugfs_unused;

struct debugfs_node* debugfs_create_dir(const char *name, struct dentry *parent);
struct debugfs_node* debugfs_create_file(const char *name, umode_t mode, struct debugfs_node *parent, void *data, const struct file_operations *fops);
int debugfs_file_get(struct dentry *dentry);

struct blah {
	int a;
	struct dentry *foo;
	struct dentry *bar;
	struct dentry *baz;
	struct dentry *used_inner;
	struct dentry *unused;

	struct dentry *debugfs_foo_unused;
	struct dentry *debugfs_bar_unused;

	struct {
		struct dentry *inner;
	} inner;
};

struct wrapper {
	int hi;
	struct blah *inner;
};

struct decoy {
	/* This should not be changed */
	struct dentry *foo;
};

struct file_operations fops = {
};

static struct dentry *my_debugfs_helper(struct dentry *parent, const char *name)
{
	return debugfs_create_dir(name, parent);
}


static struct dentry *non_obvious_helper(struct dentry *parent, const char *name)
{
	struct debugfs_node *tmp = debugfs_create_dir(name, parent);
	return tmp;
}

/* This should not be changed */
static void *unrelated_dentry_parent(struct dentry *parent, const char *name)
{
	return;
}

static struct dentry *another_nested_helper(const char *name)
{
	struct dentry *foo;
	foo = my_debugfs_helper(NULL, name);
	return foo;
}

static struct dentry *returns_func_call(struct dentry *parent, const char *name)
{
	return debugfs_create_dir(name, parent);
}

int do_stuff(struct dentry *arg)
{
	struct blah *blah;

	struct dentry *debugfs_blah;
	struct dentry *a, *b;
	struct dentry *debugfs_a, *debugfs_b;

	struct dentry *throw_off;
	struct dentry *just_arg;

	struct dentry *dbgfs_throw_off;
	struct dentry *local_dir;

	struct dentry *was_null = NULL;

	struct header_struct *header;

	struct dentry *direct_assign = debugfs_create_dir("direct_assign", NULL);

	struct wrapper mywrapper;

	debugfs_create_dir("a", a);
 	debugfs_create_dir("b", b);

	throw_off = debugfs_create_dir("just_args", just_arg);

	debugfs_create_dir("was_null", was_null);

	direct_assign->d_inode = NULL;

	test = debugfs_create_dir("test_file", NULL);
	local_dir = debugfs_create_file("test_file", 0644, arg, NULL, &fops);

	blah->foo = debugfs_create_dir("foo", test);
	blah->bar = debugfs_create_file("bar", 0644, arg, blah->foo, &fops);
	debugfs_create_file("baz", 0644, arg, blah->baz, &fops);

	header->inner = debugfs_create_dir("inner", test);

	debugfs_create_dir("blah", header_dentry);

	mywrapper->inner.used_inner = debugfs_create_dir("used_inner", test);

	blah->baz = my_helper(blah->foo, "baz");

	blah->inner.inner = debugfs_create_dir("inner", test);

	struct qname *qname = d_inode(direct_assign)->i_qname;

	struct debugfs_node *tmp;
	struct qname *tmp_name = d_inode(tmp)->i_qname;
	d_inode(tmp);

	d_inode(blah->foo);
	d_inode(blah->inner.inner);

	blah->foo->d_inode;;
	blah->inner.inner->d_inode;

	struct dentry *direct = blah->foo;


}

void another_function(void)
{
	struct blah *blah;

	struct dentry *debugfs_blah;
	struct dentry *debugfs_a, *debugfs_b;

	/* This shouldn't get changed! bad */
	struct dentry *a, *b;
	struct dentry *local_dir;
	struct dentry *direct_assign;
	struct dentry *header_dentry;
}

void file_get_fakeout(void)
{
	struct dentry *d;

	debugfs_file_get(d);
}
