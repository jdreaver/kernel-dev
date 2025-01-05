# Run like "make ARM=1 ..." to build/run for ARM
ARM ?= 0
ifeq ($(ARM), 1)
  INITRAMFS_CPIO = initramfs-arm.cpio
  QEMU = qemu-system-arm -M virt -append "console=ttyAMA0,115200 root=/dev/ram rdinit=/sbin/init"
  BUSYBOX_DIR = busybox-$(BUSYBOX_VERSION)-arm
  KERNEL_TARGET = zImage
  KERNEL_IMAGE = ../linux/arch/arm/boot/$(KERNEL_TARGET)
  ROOTFS = rootfs-arm
  MAKE_CROSS_COMPILE_ARGS = ARCH=arm CROSS_COMPILE=armv7l-unknown-linux-gnueabihf-
else
  INITRAMFS_CPIO = initramfs-x86_64.cpio
  QEMU = qemu-system-x86_64 -append "console=ttyS0 root=/dev/ram rdinit=/sbin/init"
  BUSYBOX_DIR = busybox-$(BUSYBOX_VERSION)-x86_64
  KERNEL_TARGET = bzImage
  KERNEL_IMAGE = ../linux/arch/x86_64/boot/$(KERNEL_TARGET)
  ROOTFS = rootfs-x86_64
  MAKE_CROSS_COMPILE_ARGS =
endif

BUSYBOX_VERSION = 1.36.1
BUSYBOX_BASENAME = busybox-$(BUSYBOX_VERSION)
BUSYBOX_TARBALL = $(BUSYBOX_BASENAME).tar.bz2
BUSYBOX_URL = https://busybox.net/downloads/$(BUSYBOX_TARBALL)
BUSYBOX_README = $(BUSYBOX_DIR)/README
BUSYBOX_CONFIG = $(BUSYBOX_DIR)/.config
BUSYBOX_BUILD = $(BUSYBOX_DIR)/busybox
ROOTFS_BUSYBOX = $(ROOTFS)/bin/busybox

.PHONY: all
all: $(INITRAMFS_CPIO) $(KERNEL_IMAGE)

.PHONY: run
run: all
	$(QEMU) -m 512 -kernel $(KERNEL_IMAGE) -initrd $(INITRAMFS_CPIO) -nographic

$(KERNEL_IMAGE):
	cd ../linux && make $(MAKE_CROSS_COMPILE_ARGS) $(KERNEL_TARGET) -j$$(nproc)

$(BUSYBOX_README):
	wget $(BUSYBOX_URL)
	tar -xjf $(BUSYBOX_TARBALL)
	mv $(BUSYBOX_BASENAME) $(BUSYBOX_DIR)
	rm $(BUSYBOX_TARBALL)

$(BUSYBOX_CONFIG): $(BUSYBOX_README)
	cd $(BUSYBOX_DIR) && make $(MAKE_CROSS_COMPILE_ARGS) defconfig && sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config

$(BUSYBOX_BUILD): $(BUSYBOX_CONFIG)
	cd $(BUSYBOX_DIR) && make $(MAKE_CROSS_COMPILE_ARGS) busybox -j$$(nproc)

$(ROOTFS_BUSYBOX): $(BUSYBOX_BUILD)
	rm -rf $(ROOTFS)
	mkdir -p $(ROOTFS)/bin
	cd $(BUSYBOX_DIR) && make $(MAKE_CROSS_COMPILE_ARGS) CONFIG_PREFIX=../$(ROOTFS) install

	mkdir -p $(ROOTFS)/proc
	mkdir -p $(ROOTFS)/sys
	mkdir -p $(ROOTFS)/dev

	mkdir -p $(ROOTFS)/etc/init.d
	echo "#!/bin/sh" > $(ROOTFS)/etc/init.d/rcS
	echo "set -eux" >> $(ROOTFS)/etc/init.d/rcS
	echo "mount -t proc proc /proc" >> $(ROOTFS)/etc/init.d/rcS
	echo "mount -t sysfs sysfs /sys" >> $(ROOTFS)/etc/init.d/rcS
	echo "mount -t devtmpfs devtmpfs /dev" >> $(ROOTFS)/etc/init.d/rcS
	echo "exec /bin/sh" >> $(ROOTFS)/etc/init.d/rcS
	chmod +x $(ROOTFS)/etc/init.d/rcS

$(INITRAMFS_CPIO): $(ROOTFS_BUSYBOX)
	cd $(ROOTFS) && find . | cpio -o --format=newc > ../$(INITRAMFS_CPIO)

.PHONY: clean
clean:
	rm -rf rootfs* busybox* initramfs*
