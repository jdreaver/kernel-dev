UBOOT_REPO = u-boot
UBOOT_README = $(UBOOT_REPO)/README
UBOOT = $(UBOOT_REPO)/u-boot.dtb
UBOOT_NODTB = $(UBOOT_REPO)/u-boot-nodtb.bin
UBOOT_DEVICE_TREE = stm32mp157a-dk1

# FIP_BIN = fip-$(UBOOT_DEVICE_TREE).bin

CROSS_COMPILE_ARG = CROSS_COMPILE=armv7l-unknown-linux-gnueabihf-

.PHONY: all
all: $(UBOOT)

$(UBOOT_README):
	git clone https://source.denx.de/u-boot/u-boot.git

$(UBOOT): $(UBOOT_README)
	cd $(UBOOT_REPO) && make $(CROSS_COMPILE_ARG) stm32mp15_defconfig && make $(CROSS_COMPILE_ARG) DEVICE_TREE=$(UBOOT_DEVICE_TREE) -j$$(nproc)

# $(FIP_BIN): $(UBOOT)
# 	fiptool --verbose update --nt-fw $(UBOOT_NODTB) --hw-config $(UBOOT) $@
