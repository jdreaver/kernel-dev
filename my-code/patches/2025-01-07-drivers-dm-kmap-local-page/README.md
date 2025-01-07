# Replace `kmap` with `kmap_local_page` in `drivers/dm`

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
