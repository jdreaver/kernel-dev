BUILDROOT_OUTPUT = $(PWD)/output

.PHONY: all
all: run-generate-files
	make -C ../buildroot BR2_EXTERNAL=$(PWD) O=$(BUILDROOT_OUTPUT) reaver_beaglebone_defconfig
	make -C ../buildroot O=$(BUILDROOT_OUTPUT)

.PHONY: run-generate-files
run-generate-files:
	./generate-files.sh
