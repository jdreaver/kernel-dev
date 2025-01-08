# Remove old `deprecated_apis` from `checkpatch.pl`

## TODO

- [x] Generate patch
- [x] Add emails. Probably send to the RCU list and add Paul Mckenney since that is where the original patch went
- [ ] Send the patch

## Background

`checkpatch.pl` has a `deprecated_apis` table that looks like this:

```perl
our %deprecated_apis = (
	"synchronize_rcu_bh"			=> "synchronize_rcu",
	"synchronize_rcu_bh_expedited"		=> "synchronize_rcu_expedited",
	"call_rcu_bh"				=> "call_rcu",
	"rcu_barrier_bh"			=> "rcu_barrier",
	"synchronize_sched"			=> "synchronize_rcu",
	"synchronize_sched_expedited"		=> "synchronize_rcu_expedited",
	"call_rcu_sched"			=> "call_rcu",
	"rcu_barrier_sched"			=> "rcu_barrier",
	"get_state_synchronize_sched"		=> "get_state_synchronize_rcu",
	"cond_synchronize_sched"		=> "cond_synchronize_rcu",
	"kmap"					=> "kmap_local_page",
	"kunmap"				=> "kunmap_local",
	"kmap_atomic"				=> "kmap_local_page",
	"kunmap_atomic"				=> "kunmap_local",
);
```

We can remove all of the `rcu`-related entries (everything before `kmap`) because the deprecated APIs no longer exist.

They were added in 2018 in <https://github.com/jdreaver/linux/commit/9189c7e706038a508567cb2e46ccdb68b08f4ac7>
- <https://lore.kernel.org/all/20181111192904.3199-13-paulmck@linux.ibm.com/>

No special tree for this change:

```
CHECKPATCH
M:	Andy Whitcroft <apw@canonical.com>
M:	Joe Perches <joe@perches.com>
R:	Dwaipayan Ray <dwaipayanray1@gmail.com>
R:	Lukas Bulwahn <lukas.bulwahn@gmail.com>
S:	Maintained
F:	scripts/checkpatch.pl
```

Similar patch that removed something for checkpatch that was for RCU: <https://lore.kernel.org/rcu/20231013115902.1059735-2-frederic@kernel.org/>
