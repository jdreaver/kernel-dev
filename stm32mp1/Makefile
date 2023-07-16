UBOOT_REPO = u-boot
UBOOT_README = $(UBOOT_REPO)/README
UBOOT_CONFIG = $(UBOOT_REPO)/.config
UBOOT = $(UBOOT_REPO)/u-boot.dtb
UBOOT_NODTB = $(UBOOT_REPO)/u-boot-nodtb.bin
UBOOT_DEVICE_TREE = stm32mp157a-dk1

CROSS_COMPILE_ARG = CROSS_COMPILE=armv7l-unknown-linux-gnueabihf-

.PHONY: all
all: $(UBOOT)

$(UBOOT_README):
	git clone https://source.denx.de/u-boot/u-boot.git

$(UBOOT_CONFIG): $(UBOOT_README)
	make -C $(UBOOT_REPO) $(CROSS_COMPILE_ARG) stm32mp15_basic_defconfig
	echo 'CONFIG_CMD_CONFIG=y' >> $(UBOOT_CONFIG)
	make -C $(UBOOT_REPO) $(CROSS_COMPILE_ARG) oldconfig

$(UBOOT): $(UBOOT_CONFIG)
	make -C $(UBOOT_REPO) $(CROSS_COMPILE_ARG) DEVICE_TREE=$(UBOOT_DEVICE_TREE) -j$$(nproc)

SDCARD_DEV =

.PHONY: flash-sdcard
flash-sdcard: $(UBOOT)
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
	sudo dd if=u-boot/u-boot.img of=$(SDCARD_DEV)3
