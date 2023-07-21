BUILDROOT_OUTPUT = $(PWD)/output

.PHONY: all
all:
	make -C ../buildroot BR2_EXTERNAL=$(PWD) O=$(BUILDROOT_OUTPUT) reaver_beaglebone_defconfig
	make -C ../buildroot O=$(BUILDROOT_OUTPUT)
