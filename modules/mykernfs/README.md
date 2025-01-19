# `mykernfs`, a kernel module implementing an psuedo-filesystem using `kernfs`

(**NOTE:** The kernel doesn't actually export the necessary `kernfs` modules, so I'll have to move this to an in-tree filesystem and record what I do on a branch.)

This kernel module is a followup to [`myfs`](../myfs) and [`mydebugfs`](../mydebugfs). It uses `kernfs` to build a toy pseudo-filesystem.

## Usage

The filesystem contains a tree of counters. A user can create sub-directories to add more counters. Nodes can also show the counts for all of their children. Here is an example, where `mykernfs` is mounted a `/mykernfs`:

```
/mykernfs
├── counter
├── sums
├── sub1/
│   ├── counter
│   └── sums
└── sub2/
    ├── counter
    ├── sums
    ├── sub3/
    │   ├── counter
    │   └── sums
    └── sub4/
        ├── counter
        └── sums
```

When a directory is created, it is automatically populated with two files: `counter` and `sums`:

- `counter` reports the current count for that node, and every time it is read it increments by 1. It can be set to any number by writing that number to the file:

  ```
  $ cat counter
  0
  $ cat counter
  1
  $ echo 5 > counter
  $ cat counter
  5
  $ cat counter
  6
  ```

- `sums` reports the cumulative sum of counts for the current node plus all children. It doesn't not modify `counter` for any nodes.

  ```
  $ cat /mykernfs/sub2/sub3/sums
  sub3/ 5
  $ cat /mykernfs/sums
  sub1/ 5
  sub2/sub3/ 4
  sub2/sub4/ 7
  sub2/ 11
  / 16
  ```

(TODO: It would be nice to show this as a tree, but for now a depth-first search is easier.)

## Example usage

Here is a run of the test script:

```
TODO
```
