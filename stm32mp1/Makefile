UBOOT_REPO = u-boot
UBOOT_README = $(UBOOT_REPO)/README
UBOOT = $(UBOOT_REPO)/u-boot.dtb
UBOOT_NODTB = $(UBOOT_REPO)/u-boot-nodtb.bin
UBOOT_DEVICE_TREE = stm32mp157a-dk1

TFA_REPO = trusted-firmware-a
TFA_README = $(TFA_REPO)/readme.rst
TFA_BIN = tf-a-stm32mp157a-dk1.stm32

CROSS_COMPILE_ARG = CROSS_COMPILE=armv7l-unknown-linux-gnueabihf-

.PHONY: all
all: $(UBOOT) $(TFA_BIN)

$(UBOOT_README):
	git clone https://source.denx.de/u-boot/u-boot.git

$(UBOOT): $(UBOOT_README)
	make -C $(UBOOT_REPO) $(CROSS_COMPILE_ARG) stm32mp15_defconfig
	make -C $(UBOOT_REPO) $(CROSS_COMPILE_ARG) DEVICE_TREE=$(UBOOT_DEVICE_TREE) -j$$(nproc)

$(TFA_README):
	git clone https://git.trustedfirmware.org/TF-A/trusted-firmware-a.git
	git checkout v2.7

$(TFA_BIN): $(TFA_README) $(UBOOT)
	make -C $(TFA_REPO) V=1 $(CROSS_COMPILE_ARG) ARM_ARCH_MAJOR=7 ARCH=aarch32 PLAT=stm32mp1 AARCH32_SP=sp_min DTB_FILE_NAME=stm32mp157a-dk1.dtb BL33=$(UBOOT_NODTB) BL33_CFG=$(UBOOT) STM32MP_SDMMC=1 fip all -j $$(nproc)

# $(FIP_BIN): $(UBOOT)
# 	fiptool --verbose update --nt-fw $(UBOOT_NODTB) --hw-config $(UBOOT) $@
