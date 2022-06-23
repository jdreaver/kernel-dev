# Kernel Dev Tools

This is a repo I use to support my own Linux kernel development. I put
scripts/tools here instead of inside the actual kernel tree. It is expected that
this repo will live on my machine, and any kernel trees will live under this
directory, but won't be committed to this repo.

## NixOS Kernel Resources

- https://nixos.wiki/wiki/Linux_kernel
- https://nixos.wiki/wiki/Kernel_Debugging_with_QEMU

## TODO

- Set up QEMU dev env
  - https://nixos.wiki/wiki/Kernel_Debugging_with_QEMU
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
