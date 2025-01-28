# Migrate `debugfs` to use `kernfs` under the hood

Related: [2025-01-19-sample-kernfs](../2025-01-19-sample-kernfs) and [2025-01-22-port-tracefs-kernfs](../2025-01-22-port-tracefs-kernfs).

Storing patches in this directory with:

```bash
git format-patch master...HEAD \
      --base=origin/master \
      -o ../patches/2025-01-28-migrate-debugfs-kernfs/ \
      --cover-letter \
      --to 'Greg Kroah-Hartman <gregkh@linuxfoundation.org>' \
      --to 'Steven Rostedt <rostedt@goodmis.org>' \
      --cc 'Tejun Heo <tj@kernel.org>' \
      --cc 'Christian Brauner <brauner@kernel.org>' \
      --cc 'linux-fsdevel@vger.kernel.org' \
      --cc 'linux-kernel@vger.kernel.org'
```

# TODO

- Get feedback on approach
