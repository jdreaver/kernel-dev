INITRAMFS_CPIO = initramfs.cpio
KERNEL_IMAGE = ../linux/arch/arm/boot/zImage

.PHONY: all
all: $(INITRAMFS_CPIO) $(ROOTFS_KERNEL_IMAGE)

.PHONY: run
run: all
	qemu-system-arm -m 256 -M virt -kernel $(KERNEL_IMAGE) -initrd $(INITRAMFS_CPIO) -append "console=ttyAMA0,115200 root=/dev/ram rdinit=/sbin/init" -nographic

MAKE_CROSS_COMPILE_ARGS = ARCH=arm CROSS_COMPILE=armv7l-unknown-linux-gnueabihf-

$(KERNEL_IMAGE):
	cd ../linux && make $(MAKE_CROSS_COMPILE_ARGS) zImage -j$$(nproc)

BUSYBOX_VERSION = 1.36.1
BUSYBOX_DIR = busybox-$(BUSYBOX_VERSION)
BUSYBOX_TARBALL = $(BUSYBOX_DIR).tar.bz2
BUSYBOX_URL = https://busybox.net/downloads/$(BUSYBOX_TARBALL)
BUSYBOX_README = $(BUSYBOX_DIR)/README
BUSYBOX_CONFIG = $(BUSYBOX_DIR)/.config
BUSYBOX_BUILD = $(BUSYBOX_DIR)/busybox
ROOTFS = rootfs
ROOTFS_BUSYBOX = $(ROOTFS)/bin/busybox

$(BUSYBOX_README):
	wget $(BUSYBOX_URL)
	tar -xjf $(BUSYBOX_TARBALL)
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
	rm -rf $(ROOTFS) $(BUSYBOX_DIR) $(BUSYBOX_TARBALL) $(INITRAMFS_CPIO)
