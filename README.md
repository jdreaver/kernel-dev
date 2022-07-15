# Kernel Dev Tools

This is a repo I use to support my own Linux kernel development. I put
scripts/tools here instead of inside the actual kernel tree. It is expected that
this repo will live on my machine, and any kernel trees will live under this
directory, but won't be committed to this repo.

## Usage

Here is a typical workflow with bells and whistles:
1. Get a linux kernel source tree, with either of these options:

   ```
   $ git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
   # or
   $ ./fetch-kernel-tarball.sh 5.18.6
   ```
2. Configure the kernel, using a QEMU configuration with `./minimal-qemu-kernel-config.sh linux`
3. Create a QEMU image using `./create-qemu-image.sh <debian|nixos>`
4. Compile the kernel with `cd linux/ && make -j32`
5. Run the kernel with QEMU image using something like:

   ```
   $ ./run-qemu-kernel.sh linux nixos.img /path/to/shared-files
   ```

    `/path/to/shared-files` here is a directory that will be packaged up into
    the QEMU `.img` file and mounted at `/shared` in the VM. This arg is
    optional, but it is useful for e.g. adding compiled, out-of-tree kernel
    modules.

## Misc resources

QEMU dev env:
- https://nixos.wiki/wiki/Kernel_Debugging_with_QEMU
  - https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/virtualisation/qemu-vm.nix
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
- Nice explanation of using -nographic with available options
  https://web.archive.org/web/20180104171638/http://nairobi-embedded.org/qemu_monitor_console.html
- ClangBuiltLinux has a repo super similar to this repo, including QEMU and
  buildroot scripts https://github.com/ClangBuiltLinux/boot-utils

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

Getting started, things to do
- [Kernel dev
  process](https://www.kernel.org/doc/html/latest/process/development-process.html)
- https://github.com/agelastic/eudyptula
- https://kernsec.org/wiki/index.php/Kernel_Self_Protection_Project
