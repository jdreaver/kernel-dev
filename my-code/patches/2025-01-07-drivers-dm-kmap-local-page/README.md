# Replace `kmap` with `kmap_local_page` in `drivers/dm`

## TODO

- Read [LWN article: Atomic kmaps become local (2020)](https://lwn.net/Articles/836144/)
- Think long and hard about correctness of patch
- Generate patch against `git://git.kernel.org/pub/scm/linux/kernel/git/device-mapper/linux-dm.git`
  - Existing commit against `torvalds/linux` <https://github.com/jdreaver/linux/commit/f068680d16e22318f48ed56f73d174ba870fe4fb>
- Test running with an LVM setup in QEMU
- Go through all guides and checklists in <https://docs.kernel.org/process/index.html>
- Test sending email to myself
- Submit

## How I found this

I ran `checkpatch.pl drivers/dm/*.[ch]` and found a bunch of warnings like:

```
WARNING: Deprecated use of 'kmap_atomic', prefer 'kmap_local_page' instead
#685: FILE: drivers/md/md-bitmap.c:685:
+	sb = kmap_atomic(bitmap->storage.sb_page);

...

WARNING: Deprecated use of 'kunmap_atomic', prefer 'kunmap_local' instead
#705: FILE: drivers/md/md-bitmap.c:705:
+	kunmap_atomic(sb);

...
```

## Relevant info

- Relevant [LWN article: Atomic kmaps become local (2020)](https://lwn.net/Articles/836144/)
- `checkpatch.pl` source code for this check: <https://github.com/jdreaver/linux/blob/059dd502b263d8a4e2a84809cf1068d6a3905e6f/scripts/checkpatch.pl#L847-L850>
  - Commit that added the check: <https://github.com/jdreaver/linux/commit/defdaff15a84c68521c5f02b157fc8541e0356f3>
- Similar patch from Dec 2023: <https://lore.kernel.org/linux-mm/20231215084417.2002370-1-fabio.maria.de.francesco@linux.intel.com/T/>

I searched for open patches with `kmap` in the title and didn't find any: <https://lore.kernel.org/dm-devel/?q=kmap>

Christophe Hellwig did a large migration to `kmap_local_page` but didn't get all of `dm` <https://lore.kernel.org/dm-devel/20210727055646.118787-1-hch@lst.de/>

Maintaners block:

```
DEVICE-MAPPER  (LVM)
M:	Alasdair Kergon <agk@redhat.com>
M:	Mike Snitzer <snitzer@kernel.org>
M:	Mikulas Patocka <mpatocka@redhat.com>
L:	dm-devel@lists.linux.dev
S:	Maintained
Q:	http://patchwork.kernel.org/project/dm-devel/list/
T:	git git://git.kernel.org/pub/scm/linux/kernel/git/device-mapper/linux-dm.git
F:	Documentation/admin-guide/device-mapper/
F:	drivers/md/Kconfig
F:	drivers/md/Makefile
F:	drivers/md/dm*
F:	drivers/md/persistent-data/
F:	include/linux/device-mapper.h
F:	include/linux/dm-*.h
F:	include/uapi/linux/dm-*.h
```
