UBOOT_REPO = u-boot
UBOOT_README = $(UBOOT_REPO)/README
UBOOT_CONFIG = $(UBOOT_REPO)/.config
UBOOT_IMG = $(UBOOT_REPO)/u-boot.img
UBOOT_NODTB = $(UBOOT_REPO)/u-boot-nodtb.bin
UBOOT_DEVICE_TREE = stm32mp157a-dk1

CROSS_COMPILE_ARG = CROSS_COMPILE=armv7l-unknown-linux-gnueabihf-

KERNEL_CONFIG = ../linux/.config

TFTP_DIR = /srv/tftp
KERNEL_IMAGE = $(TFTP_DIR)/zImage

ROOTFS = /nfs-export/rootfs
ROOTFS_BUSYBOX = $(ROOTFS)/bin/busybox

.PHONY: all
all: $(UBOOT_IMG) $(KERNEL_IMAGE) $(ROOTFS_BUSYBOX)

$(UBOOT_README):
	git clone https://source.denx.de/u-boot/u-boot.git

$(UBOOT_CONFIG): $(UBOOT_README)
	make -C $(UBOOT_REPO) $(CROSS_COMPILE_ARG) stm32mp15_basic_defconfig
	echo 'CONFIG_CMD_CONFIG=y' >> $(UBOOT_CONFIG)
	make -C $(UBOOT_REPO) $(CROSS_COMPILE_ARG) oldconfig

$(UBOOT_IMG): $(UBOOT_CONFIG)
	make -C $(UBOOT_REPO) $(CROSS_COMPILE_ARG) DEVICE_TREE=$(UBOOT_DEVICE_TREE) -j$$(nproc)

$(KERNEL_CONFIG):
	make -C ../linux ARCH=arm $(CROSS_COMPILE_ARG) multi_v7_defconfig
        # Disable a bunch of SOCs and options we don't need
	cd ../linux && scripts/config \
          --disable CONFIG_GCC_PLUGINS \
          --disable CONFIG_DRM \
          --disable CONFIG_ARCH_EMEV2 \
          --disable CONFIG_ARCH_INTEL_SOCFPGA \
          --disable CONFIG_ARCH_MEDIATEK \
          --disable CONFIG_ARCH_MMP \
          --disable CONFIG_ARCH_MSM8916 \
          --disable CONFIG_ARCH_MSM8960 \
          --disable CONFIG_ARCH_MSM8974 \
          --disable CONFIG_ARCH_MVEBU \
          --disable CONFIG_ARCH_R7S72100 \
          --disable CONFIG_ARCH_R7S9210 \
          --disable CONFIG_ARCH_R8A73A4 \
          --disable CONFIG_ARCH_R8A7740 \
          --disable CONFIG_ARCH_R8A7742 \
          --disable CONFIG_ARCH_R8A7743 \
          --disable CONFIG_ARCH_R8A7744 \
          --disable CONFIG_ARCH_R8A7745 \
          --disable CONFIG_ARCH_R8A77470 \
          --disable CONFIG_ARCH_R8A7778 \
          --disable CONFIG_ARCH_R8A7779 \
          --disable CONFIG_ARCH_R8A7790 \
          --disable CONFIG_ARCH_R8A7791 \
          --disable CONFIG_ARCH_R8A7792 \
          --disable CONFIG_ARCH_R8A7793 \
          --disable CONFIG_ARCH_R8A7794 \
          --disable CONFIG_ARCH_R9A06G032 \
          --disable CONFIG_ARCH_RCAR_GEN2 \
          --disable CONFIG_ARCH_RENESAS \
          --disable CONFIG_ARCH_RMOBILE \
          --disable CONFIG_ARCH_ROCKCHIP \
          --disable CONFIG_ARCH_RZN1 \
          --disable CONFIG_ARCH_SH73A0 \
          --disable CONFIG_ARCH_SPEAR13XX \
          --disable CONFIG_ARCH_STI \
          --disable CONFIG_ARCH_SUNPLUS \
          --disable CONFIG_ARCH_SUNXI \
          --disable CONFIG_ARCH_SUNXI_MC_SMP \
          --disable CONFIG_ARCH_TEGRA \
          --disable CONFIG_ARCH_TEGRA_114_SOC \
          --disable CONFIG_ARCH_TEGRA_124_SOC \
          --disable CONFIG_ARCH_TEGRA_2x_SOC \
          --disable CONFIG_ARCH_TEGRA_3x_SOC \
          --disable CONFIG_ARCH_U8500 \
          --disable CONFIG_ARCH_UNIPHIER \
          --disable CONFIG_ARCH_VEXPRESS \
          --disable CONFIG_ARCH_VEXPRESS_CORTEX_A5_A9_ERRATA \
          --disable CONFIG_ARCH_VEXPRESS_SPC \
          --disable CONFIG_ARCH_VEXPRESS_TC2_PM \
          --disable CONFIG_ARCH_VT8500 \
          --disable CONFIG_ARCH_WM8850 \
          --disable CONFIG_ARCH_ZYNQ
	make -C ../linux ARCH=arm $(CROSS_COMPILE_ARG) olddefconfig

$(KERNEL_IMAGE): $(KERNEL_CONFIG)
	make -C ../linux ARCH=arm $(CROSS_COMPILE_ARG) -j$$(nproc)

	sudo cp ../linux/arch/arm/boot/zImage $(TFTP_DIR)/
	sudo cp ../linux/arch/arm/boot/dts/st/stm32mp157a-dk1.dtb $(TFTP_DIR)/

BUSYBOX_VERSION = 1.36.1
BUSYBOX_DIR = busybox-$(BUSYBOX_VERSION)
BUSYBOX_TARBALL = $(BUSYBOX_DIR).tar.bz2
BUSYBOX_URL = https://busybox.net/downloads/$(BUSYBOX_TARBALL)
BUSYBOX_README = $(BUSYBOX_DIR)/README
BUSYBOX_CONFIG = $(BUSYBOX_DIR)/.config
BUSYBOX_BUILD = $(BUSYBOX_DIR)/busybox

$(BUSYBOX_README):
	wget $(BUSYBOX_URL)
	tar -xjf $(BUSYBOX_TARBALL)
	rm $(BUSYBOX_TARBALL)

$(BUSYBOX_CONFIG): $(BUSYBOX_README)
	cd $(BUSYBOX_DIR) && make ARCH=arm $(CROSS_COMPILE_ARG) defconfig && sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config

$(BUSYBOX_BUILD): $(BUSYBOX_CONFIG)
	cd $(BUSYBOX_DIR) && make ARCH=arm $(CROSS_COMPILE_ARG) busybox -j$$(nproc)

$(ROOTFS_BUSYBOX): $(BUSYBOX_BUILD)
	sudo rm -rf $(ROOTFS)
	sudo mkdir $(ROOTFS)
	sudo chown $(USER):$(USER) $(ROOTFS)

	mkdir -p $(ROOTFS)/bin
	cd $(BUSYBOX_DIR) && make ARCH=arm $(CROSS_COMPILE_ARG) CONFIG_PREFIX=$(ROOTFS) install

	mkdir -p $(ROOTFS)/proc
	mkdir -p $(ROOTFS)/sys
	mkdir -p $(ROOTFS)/dev

	mkdir -p $(ROOTFS)/etc/init.d
	echo "#!/bin/sh" > $(ROOTFS)/etc/init.d/rcS
	echo "set -eux" >> $(ROOTFS)/etc/init.d/rcS
	echo "mount -t proc proc /proc" >> $(ROOTFS)/etc/init.d/rcS
	echo "mount -t sysfs sysfs /sys" >> $(ROOTFS)/etc/init.d/rcS
	echo "exec /bin/sh" >> $(ROOTFS)/etc/init.d/rcS
	chmod +x $(ROOTFS)/etc/init.d/rcS

	sudo chown -R root:root $(ROOTFS)

SDCARD_DEV =

.PHONY: flash-sdcard
flash-sdcard: $(UBOOT_IMG)
	@[ "${SDCARD_DEV}" ] || ( echo ">> SDCARD_DEV is not set"; exit 1 )
	sudo sgdisk -o $(SDCARD_DEV)
	sudo sgdisk --resize-table=128 -a 1 \
          -n 1:34:545     -c 1:fsbl1 \
          -n 2:546:1057   -c 2:fsbl2 \
          -n 3:1058:5153  -c 3:ssbl \
          -n 4:5154:      -c 4:rootfs -A 4:set:2 \
          -p $(SDCARD_DEV)
	sudo dd if=u-boot/u-boot-spl.stm32 of=$(SDCARD_DEV)1
	sudo dd if=u-boot/u-boot-spl.stm32 of=$(SDCARD_DEV)2
	sudo dd if=$(UBOOT_IMG) of=$(SDCARD_DEV)3
