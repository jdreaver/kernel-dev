obj-m := hello.o
KDIR := ../../../linux
PWD := $(shell pwd)

.PHONY: all
all:
	make -C $(KDIR) M=$(PWD) modules

compile_commands.json:
	make -C $(KDIR) M=$(PWD) compile_commands.json

.PHONY: clean
clean:
	make -C $(KDIR) M=$(PWD) clean
