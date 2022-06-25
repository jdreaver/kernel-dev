# Kernel Dev Tools

This is a repo I use to support my own Linux kernel development. I put
scripts/tools here instead of inside the actual kernel tree. It is expected that
this repo will live on my machine, and any kernel trees will live under this
directory, but won't be committed to this repo.

## TODO

- Try Eudyptula challenge
- Set up QEMU dev env
  - https://nixos.wiki/wiki/Kernel_Debugging_with_QEMU
    - Alternate NixOS QEMU image
      https://gist.github.com/tarnacious/f9674436fff0efeb4bb6585c79a3b9ff
    - NixOS qcow2 build
      https://gist.github.com/jahkeup/14c0f35383bf949fdd92fbfa20184b4f
    - https://discourse.nixos.org/t/how-to-build-a-standalone-nixos-qemu-vm/5688/4
  - https://vccolombo.github.io/cybersecurity/linux-kernel-qemu-setup/
  - https://kernel-recipes.org/en/2015/talks/speed-up-your-kernel-development-cycle-with-qemu/
    - https://www.youtube.com/watch?v=PBY9l97-lto
  - https://medium.com/@daeseok.youn/prepare-the-environment-for-developing-linux-kernel-with-qemu-c55e37ba8ade
  - https://www.collabora.com/news-and-blog/blog/2017/01/16/setting-up-qemu-kvm-for-kernel-development/

```
qemu-system-x86_64 -s \
    -kernel linux-5.18.6/arch/x86/boot/bzImage \
    -hda qemu-image.img \
    -append "root=/dev/sda console=ttyS0" \
    -enable-kvm \
    -nographic
```

### Whitespace patch

```patch
From 4130aa90c455c1c3b64593cdba0ff9843ae6c9ab Mon Sep 17 00:00:00 2001
From: David Reaver <me@davidreaver.com>
Date: Sat, 25 Jun 2022 10:03:55 -0700
Subject: [PATCH] staging: fbtft: fix alignment should match open parenthesis

Fix alignment of this line of code with the previous parenthesis, as
suggested by checkpatch.pl.

Signed-off-by: David Reaver <me@davidreaver.com>
---
 drivers/staging/fbtft/fb_tinylcd.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/staging/fbtft/fb_tinylcd.c b/drivers/staging/fbtft/fb_tinylcd.c
index 9469248f2c50..60cda57bcb33 100644
--- a/drivers/staging/fbtft/fb_tinylcd.c
+++ b/drivers/staging/fbtft/fb_tinylcd.c
@@ -38,7 +38,7 @@ static int init_display(struct fbtft_par *par)
 	write_reg(par, 0xE5, 0x00);
 	write_reg(par, 0xF0, 0x36, 0xA5, 0x53);
 	write_reg(par, 0xE0, 0x00, 0x35, 0x33, 0x00, 0x00, 0x00,
-		       0x00, 0x35, 0x33, 0x00, 0x00, 0x00);
+		  0x00, 0x35, 0x33, 0x00, 0x00, 0x00);
 	write_reg(par, MIPI_DCS_SET_PIXEL_FORMAT, 0x55);
 	write_reg(par, MIPI_DCS_EXIT_SLEEP_MODE);
 	udelay(250);
```

### Perl interpreter patch for docs

```patch
From 28f25b9b7ee205851182ed3010143eb302100432 Mon Sep 17 00:00:00 2001
From: David Reaver <me@davidreaver.com>
Date: Sat, 25 Jun 2022 12:38:18 -0700
Subject: [PATCH] scripts: get_feat.pl: use /usr/bin/env to find perl

I couldn't build the docs via `make pdfdocs` because my Linux
distribution (NixOS) doesn't put perl in that location. My understanding
`#!/usr/bin/env perl` is more portable, and with this patch I can
successfully run this script.

Tested by running this command:

./scripts/get_feat.pl rest --dir Documentation/features --arch arm

Signed-off-by: David Reaver <me@davidreaver.com>
---
 scripts/get_feat.pl | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/scripts/get_feat.pl b/scripts/get_feat.pl
index 76cfb96b59b6..5c5397eeb237 100755
--- a/scripts/get_feat.pl
+++ b/scripts/get_feat.pl
@@ -1,4 +1,4 @@
-#!/usr/bin/perl
+#!/usr/bin/env perl
 # SPDX-License-Identifier: GPL-2.0

 use strict;
```

## Misc resources

NixOS:
- https://nixos.wiki/wiki/Linux_kernel
- https://nixos.wiki/wiki/Kernel_Debugging_with_QEMU

Email:
- https://www.kernel.org/doc/html/latest/process/email-clients.html
- https://offlinemark.com/2020/09/26/tips-for-submitting-your-first-linux-kernel-patch/
- https://ane.iki.fi/emacs/patches.html
- https://git-send-email.io
- https://devtut.github.io/git/git-send-email.html#sending-patches-by-mail

First time contributions:
- https://kernelnewbies.org/
  - https://kernelnewbies.org/KernelHacking
    - Suggests running `checkpatch.pl` on `drivers/staging` directories
    - Also suggests running
      [Coccinelle](https://www.kernel.org/doc/html/v4.15/dev-tools/coccinelle.html)
- Very informative patch set with revisions, followups, responses from Greg
  K-H's autobot, etc
  https://lore.kernel.org/linux-staging/ac6d83d6-c8b0-e0bd-10aa-a49897679edb@gmail.com/T/
  - Versioning patch revisions
    https://kernelnewbies.org/FirstKernelPatch#Versioning_one_patch_revision
- https://www.linux.com/news/three-ways-beginners-contribute-linux-kernel/
- https://williamdurand.fr/2021/02/22/first-patch-in-the-linux-kernel/
- [tpiekarski's comment from discussion "Is reading Linux kernel development helpful in 2020? Is it outdated?"](https://www.reddit.com/r/kernel/comments/g0i4qq/is_reading_linux_kernel_development_helpful_in/fn9swcs/)
- [How to become a Kernel Developer?](https://www.reddit.com/r/kernel/comments/tniuhx/how_to_become_a_kernel_developer/)
- [How should I start kernel development?](https://www.reddit.com/r/kernel/comments/hf6bmv/how_should_i_start_kernel_development/)
- [What (not how) to contribute to the kernel](https://www.reddit.com/r/kernel/comments/rc6t73/what_not_how_to_contribute_to_the_kernel/)
- [Recommendations for newer books on kernel development?](https://www.reddit.com/r/kernel/comments/ajho69/recommendations_for_newer_books_on_kernel/)

Getting started
- [Kernel dev
  process](https://www.kernel.org/doc/html/latest/process/development-process.html)
- https://github.com/agelastic/eudyptula
