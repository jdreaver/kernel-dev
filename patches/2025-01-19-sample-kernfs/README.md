# Simple pseudo-filesystem sample build on top of `kernfs`

I'm working in my own `linux` tree in a branch called `davidreaver/sample-kernfs` and is located at <https://github.com/jdreaver/linux/tree/davidreaver/sample-kernfs> (diff URL: <https://github.com/jdreaver/linux/compare/master...jdreaver:linux:davidreaver/sample-kernfs>). I'm storing patches in this directory with:

```sh
cd ~/git/kernel-dev/linux
git switch davidreaver/sample-kernfs
git format-patch master...HEAD -o ../patches/2025-01-19-sample-kernfs/
```

## TODO

Code:

- Memory leaks
  - Fix kmemleak for `kernfs_create_root`. How does cgroups/sysfs do it?
- Ensure we have locking for any parent/child relationship modifications in `sample_kern_directory`.
  - Check if `kernfs` provides top-level locks on all of these actions. We don't want to add extra locks! If `kernfs` locks, document it.
    - In particular, does `kernfs_remove_self` (which removes self-protection) kill our locking?
- If we end up having to write a function to recursively remove nodes, consider bringing back `sums` file idea instead of the `inc` file
- If I iterate through child directories, avoid recursion (unless it makes the code extremely complicated)
- Consider moving my own data structures to a separate file if I have to manipulate them a lot
- Test multiple sample_kernfs roots at once
- Run through all of these cool tools to find undefined behavior, memory leaks, etc <https://docs.kernel.org/dev-tools/index.html>

Patches:

- Fill out patch descriptions more
- Write cover letter
- Ensure each commit compiles and works as intended!
- Either add documentation for `kernfs` in this patch series or mention that I want to add documentation.

## Cover letter (WIP)

This patch series creates a pseudo-filesystem built on top of kernfs in
samples/kernfs/.

TODO:

- Mention how patches are split up (to demonstrate the "steps" of building a pseudo-filesystem on top of `kernfs`, where each step adds a feature).
- Is the `inc` file too much? Should I remove it?
