obj-m = hello.o

linux_src=../../../linux

KERNEL_MAKE=make -C $(linux_src) M=$(PWD) ARCH=arm CROSS_COMPILE=armv7l-unknown-linux-gnueabihf-

.PHONY: all
all: module compile_commands.json

.PHONY: module
module:
	$(KERNEL_MAKE) modules

compile_commands.json:
	$(KERNEL_MAKE) compile_commands.json

.PHONY: clean
clean:
	$(KERNEL_MAKE) clean

.PHONY: deploy
deploy: all
	sudo cp hello.ko /nfs-export/rootfs/
