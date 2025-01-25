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

Other tracing config options I need on top of my defaults

```bash
./scripts/config \
    --set-val CONFIG_IRQSOFF_TRACER y \
    --set-val CONFIG_TRACER_MAX_TRACE y \
    --set-val CONFIG_PREEMPT_TRACER y \
    --set-val CONFIG_SCHED_TRACER y \
    --set-val CONFIG_HWLAT_TRACER y \
    --set-val CONFIG_OSNOISE_TRACER y \
    --set-val CONFIG_TRACE_EVAL_MAP_FILE y \
    --set-val CONFIG_TRACER_SNAPSHOT y
```

## TODO

- Undo the stuff I moved to `seq_file`. `seq_file` isn't an obvious/instant win.

Prefactor:

- Elephant in the room: separating out eventfs is going to be a massive PITA. We might have to make `eventfs` an actual separate thing first.
- Perhaps we need opaque handles to wrap inodes, dentries, open files, etc so the actual patch to port to kernfs is smaller. Basically make a shim layer and the migrate the shim.
- Deal with using `inode->c_dev` to store CPU
  - Maybe store in `ftrace_buffer_info`?
- Most complicated `file_operations` is `tracing_buffers_fops`. poll, flush, splice_read, mmap, ioctl, etc
  - I wonder what people would think if we did `kernfs_inode()` as an escape hatch to set some of these to our own function?
  - Context on `flush()` at least <https://lore.kernel.org/linux-trace-kernel/20240308202432.107909457@goodmis.org/>
- Also complicated is `tracing_pipe_fops`

Code:

- Compile entire kernel or find a way to find all users and ensure I'm compiling/enabling them
  - Enable all `CONFIG_TRACE*` and `CONFIG_FTRACE*` stuff (search trace.c for stuff to enable)
- Need to set `atomic_write_len` on all `kernfs_ops`?
- Remove global info. Not sure why we need it?
- Bring back llseek?
- TODOs in the code

Testing:

- Toggle `CONFIG_LATENCY_FS_NOTIFY` because there are files in both branches of the if/else
- Iterate through all files in tracefs and read/write them
- Write a program that does reads (maybe writes?) one byte at a time
  - This doesn't work for some files, so figure those out

Before submitting:

- Double check To:/Cc: lists

Misc:

- (nevermind, can't find right branch) Use tracing tree as base (not Linus') git://git.kernel.org/pub/scm/linux/kernel/git/trace/linux-trace.git

## Ideas for splitting this up

Refactoring commits before main change (these could be merged in isolation if we want):

- Refactor how fs_context, ops, etc are dealt with
- Have eventfs use totally isolated data structures so moving tracefs by itself is easier. Move anything shared to `event_inode.c`.
  - Could be done after as well. Just move code and s/tracefs/eventfs?

## Background

Related: [2025-01-19-sample-kernfs](../2025-01-19-sample-kernfs)

Prior art: draft patch from Jan 31 2024 [Port tracefs to kernfs](https://lore.kernel.org/all/20240131-tracefs-kernfs-v1-0-f20e2e9a8d61@kernel.org/T/#u) by Christian Brauner.
