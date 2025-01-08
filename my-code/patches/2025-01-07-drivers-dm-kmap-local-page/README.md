# Replace `kmap_atomic` with `kmap_local_page` in `drivers/dm`

Patch discussion: <https://lore.kernel.org/linux-raid/20250108192131.46843-1-me@davidreaver.com/T/#u>

## TODO

- [x] Read [LWN article: Atomic kmaps become local (2020)](https://lwn.net/Articles/836144/)
- [x] Think long and hard about correctness of patch
  - Do any call sites rely on the implicit preemption/pagefault disabling that `kmap_atomic` provides?
  - Do any call sites try to sleep or schedule?
- [x] Generate patch against `mdraid` tree
  - <https://github.com/jdreaver/linux/commits/davidreaver/mdraid-kmap-local-page/>
- [x] Go through all guides and checklists in <https://docs.kernel.org/process/index.html>
- [x] Test sending email to myself
- [x] Submit

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

Maintainers block:

```
SOFTWARE RAID (Multiple Disks) SUPPORT
M:	Song Liu <song@kernel.org>
M:	Yu Kuai <yukuai3@huawei.com>
L:	linux-raid@vger.kernel.org
S:	Supported
Q:	https://patchwork.kernel.org/project/linux-raid/list/
T:	git git://git.kernel.org/pub/scm/linux/kernel/git/mdraid/linux.git
F:	drivers/md/Kconfig
F:	drivers/md/Makefile
F:	drivers/md/md*
F:	drivers/md/raid*
F:	include/linux/raid/
F:	include/uapi/linux/raid/
```

Highmem docs: <https://docs.kernel.org/mm/highmem.html#temporary-virtual-mappings>

> kmap_atomic(). This function has been deprecated; use kmap_local_page().
>
> NOTE: Conversions to kmap_local_page() must take care to follow the mapping restrictions imposed on kmap_local_page(). Furthermore, the code between calls to kmap_atomic() and kunmap_atomic() may implicitly depend on the side effects of atomic mappings, i.e. disabling page faults or preemption, or both. In that case, explicit calls to pagefault_disable() or preempt_disable() or both must be made in conjunction with the use of kmap_local_page().
