# Simple pseudo-filesystem sample build on top of `kernfs`

I'm working in my own `linux` tree in a branch called `davidreaver/sample-kernfs` and is located at <https://github.com/jdreaver/linux/tree/davidreaver/sample-kernfs> (diff URL: <https://github.com/jdreaver/linux/compare/master...jdreaver:linux:davidreaver/sample-kernfs>). I'm storing patches in this directory with:

```sh
cd ~/git/kernel-dev/linux
git switch davidreaver/sample-kernfs
rm -f ../patches/2025-01-19-sample-kernfs/*.patch && git format-patch master...HEAD --base=origin/master -o ../patches/2025-01-19-sample-kernfs/ --cover-letter
```

## TODO

Code:

- Style/comments
  - Remove the `pr_info("Loaded sample_kernfs module.\n");`
  - Use kernfs code style as an example!
  - Just use `/*   */` for all comments
  - Always have space before final return
  - Explain that kernfs serializes rmdir for us, so we don't need a lock in `sample_kernfs_remove_subtree` (verify this)
  - Consider function descriptions
  - Shorten up comment language
  - Comment `sample_kernfs_directory` fields

- Rebase against git://git.kernel.org/pub/scm/linux/kernel/git/gregkh/driver-core.git
- Ensure we have locking for any parent/child relationship modifications in `sample_kern_directory`.
  - Check if `kernfs` provides top-level locks on all of these actions. We don't want to add extra locks! If `kernfs` locks, document it.
    - In particular, does `kernfs_remove_self` (which removes self-protection) kill our locking?
- If we end up having to write a function to recursively remove nodes, consider bringing back `sums` file idea instead of the `inc` file
  - Check if we need locking! I bet we do on reads. It is different than rmdir/mkdir.
  - We could use the `kernfs_root` rwsem, I think (since we are reading)
- Consider moving my own data structures to a separate file if I have to manipulate them a lot
- Run through all of these cool tools to find undefined behavior, memory leaks, etc <https://docs.kernel.org/dev-tools/index.html>

Ideas besides `inc`:

- Whenever count is incremented in a subdirectory, increment all parents. Locking might be simpler here (or even unnecessary?)
- Recursive sum in `sums` file. I kind of don't like this because it probably requires a `rwsem`

Patches:

- Ensure each commit compiles and works as intended!
- Maybe make this an `[RFC]`

Cover letter:

## People to To/CC

- To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
- To: Tejun Heo <tj@kernel.org>
- Cc: Steven Rostedt <rostedt@goodmis.org>
- Cc: Christian Brauner <brauner@kernel.org>
- Cc: Al Viro <viro@zeniv.linux.org.uk>
- Cc: Jonathan Corbet <corbet@lwn.net>
- Cc: James Bottomley <James.Bottomley@HansenPartnership.com>
- Cc: linux-fsdevel@vger.kernel.org

## Cover letter (WIP)

Subject: samples/kernfs: Add a pseudo-filesystem to demonstrate kernfs usage

This patch series creates a pseudo-filesystem built on top of kernfs in
samples/kernfs/.

kernfs underpins the sysfs and cgroup filesystems. Many kernel developers have
considered kernfs for other pseudo-filesystems [1][2] and a draft patch was even
put forth to investigate moving tracefs to kernfs [3]. One reason kernfs isn't
used more is it is almost entirely undocumented; I certainly had to read almost
all of the kernfs code to implement this toy filesystem. This sample aims to
improve kernfs documentation by way of an example.

The README.rst file in the first patch describes how sample_kernfs works from a
user's perspective. Summary: the filesystem automatically populates directories
with counter files that increment every time they are read. Users can adjust the
increment via inc files. Counter files can be reset by writing a new value to
them.

Subsequent patches build the rest of the filesystem. The commits are structured
to guide readers in learning kernfs components and adapting them to build their
own filesystems. If reviewers would prefer this all to be in one commit, I'm
happy to do that too. Initially, I included a more complex example where you
could read the sum of all child directory counters in a parent directory, but I
didn't want to complicate the sample too much and distract from kernfs. I’m
happy to remove the inc file if reviewers feel it's unnecessary. It is funny how
even a toy can suffer from feature creep :)

This is my first substantial kernel patch, so I welcome feedback on any trivial
errors. I tested this filesystem with all of the CONFIG_DEBUG_* and similar
options I could find and I ensured none of them report any issues. They were
particularly useful when debugging a deadlock that required replacing
kernfs_remove() with kernfs_remove_self(), and discovering a memory leak fixed
with kernfs_put().

Link: https://lwn.net/Articles/960088/ [1]
Link: https://lwn.net/Articles/981155/ [2]
Link: https://lore.kernel.org/all/20240131-tracefs-kernfs-v1-0-f20e2e9a8d61@kernel.org/ [3]
