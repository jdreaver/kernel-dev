# Port `tracefs` to use `kernfs`

Working branch is <https://github.com/jdreaver/linux/tree/davidreaver/port-tracefs-kernfs/>

Storing patches in this directory with:

```bash
rm -f ../patches/2025-01-22-port-tracefs-kernfs/*.patch && \
  git format-patch master...HEAD \
      --base=origin/master \
      -o ../patches/2025-01-22-port-tracefs-kernfs/ \
      --cover-letter \
      --to 'Steven Rostedt <rostedt@goodmis.org>' \
      --to 'Masami Hiramatsu <mhiramat@kernel.org>' \
      --to 'Mathieu Desnoyers <mathieu.desnoyers@efficios.com>' \
      --cc 'Greg Kroah-Hartman <gregkh@linuxfoundation.org>' \
      --cc 'Tejun Heo <tj@kernel.org>' \
      --cc 'Christian Brauner <brauner@kernel.org>' \
      --cc 'linux-trace-kernel@vger.kernel.org' \
      --cc 'linux-fsdevel@vger.kernel.org' \
      --cc 'linux-kernel@vger.kernel.org'
```

## TODO

Code:

- Fill out the read/write/seek/etc methods (see the stuff I deleted obviously)
- Remove global info. Not sure why we need it?
- TODOs in the code

Testing:

- Do any testing :) add more items here

Before submitting:

- Double check To:/Cc: lists

## Ideas for splitting this up

Refactoring commits before main change (these could be merged in isolation if we want):

- Use seq_file stuff
- Refactor how fs_context, ops, etc are dealt with
- Have eventfs use totally isolated data structures so moving tracefs by itself is easier. Move anything shared to `event_inode.c`.
  - Could be done after as well. Just move code and s/tracefs/eventfs?

## Background

Related: [2025-01-19-sample-kernfs](../2025-01-19-sample-kernfs)

Prior art: draft patch from Jan 31 2024 [Port tracefs to kernfs](https://lore.kernel.org/all/20240131-tracefs-kernfs-v1-0-f20e2e9a8d61@kernel.org/T/#u) by Christian Brauner.
