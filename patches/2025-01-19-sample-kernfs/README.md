# Simple pseudo-filesystem sample build on top of `kernfs`

I'm working in my own `linux` tree in a branch called `davidreaver/sample-kernfs` and is located at <https://github.com/jdreaver/linux/tree/davidreaver/sample-kernfs> (diff URL: <https://github.com/jdreaver/linux/compare/master...jdreaver:linux:davidreaver/sample-kernfs>). I'm storing patches in this directory with:

```sh
cd ~/git/kernel-dev/linux
git switch davidreaver/sample-kernfs
git format-patch master...HEAD -o ../patches/2025-01-19-sample-kernfs/
```

## TODO

- Don't use a global mount. Requires editing initial patches and rebasing imo.
- Implement resetting count
- Implement `sums` file
  - Consider reimplementing this as getting the sum of all _parents_ instead of children. I suspect parents is easier.
- In cover letter, mention how patches are split up (to demonstrate the "steps" of building a pseudo-filesystem on top of `kernfs`, where each step adds a feature).
- Either add documentation for `kernfs` in this patch series or mention that I want to add documentation.

## Cover letter (WIP)

This patch series creates a pseudo-filesystem built on top of kernfs in
samples/kernfs/.
