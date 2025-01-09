NFS_ROOTFS = /nfs-export/rootfs
KERNEL = ../../linux

TFTP_DIR = /srv/tftp
KERNEL_IMAGE = $(TFTP_DIR)/zImage
DEVICETREE_OVERLAY = $(TFTP_DIR)/overlay.dtbo

.PHONY: all
all: deploy-nfs-tftp buildroot-build $(DEVICETREE_OVERLAY)

.PHONY: deploy-nfs-tftp
deploy-nfs-tftp: buildroot-build $(DEVICETREE_OVERLAY)
	sudo cp output/images/zImage $(TFTP_DIR)/
	sudo cp output/images/am335x-boneblack.dtb $(TFTP_DIR)/

	sudo rm -rf $(NFS_ROOTFS)
	sudo mkdir -p $(NFS_ROOTFS)
	sudo tar -C $(NFS_ROOTFS) -xf output/images/rootfs.tar

$(DEVICETREE_OVERLAY): board/reaver/beaglebone/overlay.dts
	cpp -I $(KERNEL)/include -nostdinc -undef -x assembler-with-cpp -o $<.tmp $<
	dtc -O dtb -o out.dtbo $<.tmp
	sudo cp out.dtbo $@
	rm -f $<.tmp out.dtbo

.PHONY: buildroot-build
buildroot-build:
	./buildroot-make reaver_beaglebone_defconfig
	./buildroot-make


SDCARD = output/images/sdcard.img
SDCARD_DEV =

.PHONY: flash-sdcard
flash-sdcard: $(SDCARD)
	@[ "${SDCARD_DEV}" ] || ( echo ">> SDCARD_DEV is not set"; exit 1 )
	sudo dd if=$(SDCARD) of=$(SDCARD_DEV) bs=1M status=progress
	sync
