# Kernel Dev Tools

This is a repo I use to support my own Linux kernel development. I put
scripts/tools here instead of inside the actual kernel tree. It is expected that
this repo will live on my machine, and any kernel trees will live under this
directory, but won't be committed to this repo.

## Usage

Here is a typical workflow with bells and whistles:
1. (Optional) Update the kernel source tree or get a new one

   ```bash
   $ cd linux && git pull upstream master
   # or
   $ ./scripts/fetch-kernel-tarball.sh 5.18.6
   ```
2. Configure the kernel, using a QEMU configuration with `./qemu/minimal-qemu-kernel-config.sh linux`
3. Create a QEMU image using `./qemu/create-qemu-image.sh <debian|nixos>`
4. Compile the kernel with `cd linux/ && make -j32`
5. Run the kernel with QEMU image using something like:

   ```bash
   $ ./qemu/run-qemu-kernel.sh linux nixos.img /path/to/shared-files
   ```

    `/path/to/shared-files` here is a directory that will be packaged up into
    the QEMU `.img` file and mounted at `/shared` in the VM. This arg is
    optional, but it is useful for e.g. adding compiled, out-of-tree kernel
    modules.

## Linux Kernel Language Server Protocol (LSP) Configuration

The kernel has a script to generate a `compile-commands.json` usable with LSP:

```bash
$ cd linux/
# Make a config and build the kernel
$ make mrproper
$ make defconfig
# Build just for good measure
$ make -j14
# Generate compile-commands.json
$ ./scripts/clang-tools/gen_compile_commands.py
```

## Linux Kernel Rust

```
$ make mrproper
$ make CC=clang allnoconfig defconfig rust.config
$ make CC=clang -j14
```

Note: when I use `LLVM=1` instead of `CC=clang`, I get this error when linking, even when I _don't_ enable Rust:

```
  LD      arch/x86/boot/setup.elf
ld.lld: error: section .bsdata file range overlaps with .header
>>> .bsdata range is [0x1092, 0x122B]
>>> .header range is [0x11EF, 0x126B]
```

Maybe the problem is my LLVM env for nix in general? <https://github.com/NixOS/nixpkgs/issues/217724>

### Rust resources

- [Mentorship Session: Setting Up an Environment for Writing Linux Kernel Modules in Rust](https://www.youtube.com/watch?v=tPs1uRqOnlk)
- <https://github.com/jordanisaacs/kernel-module-flake>
- <https://github.com/Rust-for-Linux/nix>
- <https://github.com/jordanisaacs/kernel-module-flake>

## Buildroot

### Raspberry Pi using external directory

1. Set up some stupid symlinks that buildroot expects (well, really the problem
   is `libtool` and `autotools` I think. `buildroot` can't use host
   libraries and pretty much compiles everything from scratch).

   ```bash
   $ sudo ln -s (which file) /usr/bin/file
   $ sudo ln -s (which true) /bin/true
   $ sudo ln -s (which awk) /usr/bin/awk
   $ sudo ln -s (which bash) /bin/bash
   ```
2. Use the external config

   ```bash
   $ cd buildroot
   $ make BR2_EXTERNAL=../buildroot-rpi reaver_rpi_defconfig menuconfig
   ```
3. Build `$ make` (no need for `-j` since buildroot uses parallelism internally, not for top level targets)
4. Copy image to SD card (see below for generic instructions)

### Raspberry Pi Generic

(These were the instructions I used before I set up the `buildroot-rpi` external infra)

Getting `buildroot` working is not too onerous, at least since I figured out
some nix quirks. Here is a general procedure:

1. Set up some stupid symlinks that buildroot expects (well, really the problem
   is `libtool` and `autotools` I think. `buildroot` can't use host
   libraries and pretty much compiles everything from scratch).

   ```bash
   $ sudo ln -s (which file) /usr/bin/file
   $ sudo ln -s (which true) /bin/true
   $ sudo ln -s (which awk) /usr/bin/awk
   $ sudo ln -s (which bash) /bin/bash
   ```

2. `git clone git://git.buildroot.net/buildroot`
3. `cd buildroot`
4. `make raspberrypi4_64_defconfig`
5. `make -j32`
6. Copy `output/images/sdcard.img` to an SD card
   (MAKE SURE TO VERIFY DEVICE NAME, REPLACE `sdz`)

   ```bash
   $ sudo dd if=output/images/sdcard.img of=/dev/sdz status=progress
   ```

7. Connect Pi serial port to USB serial port connector, use `dmesg` to find
   `tty` device name

   ```
   dmesg | grep 'cp210x converter now attached'
   [48407.800462] usb 1-4: cp210x converter now attached to ttyUSB0
   ```

8. Connect with GNU screen

   ```bash
   $ sudo screen /dev/ttyUSB0 115200
   ```

9. Boot the Pi! Log in with `root` and no password.

Cool links:
- https://www.thirtythreeforty.net/series/mastering-embedded-linux/
- Serial console
  - https://learn.adafruit.com/adafruits-raspberry-pi-lesson-5-using-a-console-cable/test-and-configure
  - https://www.jeffgeerling.com/blog/2021/attaching-raspberry-pis-serial-console-uart-debugging

## Misc resources

TODO Check out this repo for kernel dev with nix https://github.com/jordanisaacs/kernel-module-flake

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

## TODO

Embedded:
- Dev setup
  - Get booting with NFS or TFTP
    - See the bootlin labs or the Mastering Embedded Linux Book
    - NFS mounting seems to work with `# mount -v -t nfs 10.42.0.1:/nfs-export /nfs-mnt -o nolock,vers=3`
  - Consider using buildroot or nix for just a barebones setup to bootstrap NFS and/or SSH, and thereafter just syncing to board
- Buildroot
  - (Consider abandoning buildroot and figuring out a kernel dev loop with nix)
  - Set up NFS booting, and/or an initramfs for faster booting so we can have a quicker kernel dev inner loop
  - <https://buildroot.org/downloads/manual/manual.html#customize>
  - <https://buildroot.org/downloads/manual/using-buildroot-development.txt>
  - Set up my own BR2_EXTERNAL directory for rpi4 + Linux dev
