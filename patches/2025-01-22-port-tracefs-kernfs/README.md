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

- (nevermind, can't find right branch) Use tracing tree as base (not Linus') git://git.kernel.org/pub/scm/linux/kernel/git/trace/linux-trace.git

Prefactor:

- Deal with using `inode->c_dev` to store CPU
  - Maybe store in `ftrace_buffer_info`?
- Need a prefactor in trace.c (and all other users of tracefs) to try using seq ops or some wrapper so when we migrate to `kernfs_ops` it isn't a massive pain
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
