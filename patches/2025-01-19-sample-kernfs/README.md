# Simple pseudo-filesystem sample build on top of `kernfs`

I'm working in my own `linux` tree in a branch called `davidreaver/sample-kernfs` and is located at <https://github.com/jdreaver/linux/tree/davidreaver/sample-kernfs> (diff URL: <https://github.com/jdreaver/linux/compare/master...jdreaver:linux:davidreaver/sample-kernfs>). I'm storing patches in this directory with:

```sh
cd ~/git/kernel-dev/linux
git switch davidreaver/sample-kernfs
git format-patch master...HEAD -o ../patches/2025-01-19-sample-kernfs/
```

## TODO

- Move variable declarations to the top of functions in each patch
- Consider squashing the patches to create and remove directories into one
- Test multiple sample_kernfs roots at once
- Write cover letter
- Either add documentation for `kernfs` in this patch series or mention that I want to add documentation.

## Cover letter (WIP)

This patch series creates a pseudo-filesystem built on top of kernfs in
samples/kernfs/.

TODO:

- Mention how patches are split up (to demonstrate the "steps" of building a pseudo-filesystem on top of `kernfs`, where each step adds a feature).
- Is the `inc` file too much? Should I remove it?
