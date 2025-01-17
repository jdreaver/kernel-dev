obj-m := myfs.o
KDIR := ../../linux
PWD := $(shell pwd)

# Enable debug symbols
EXTRA_CFLAGS := -g -DDEBUG

.PHONY: all
all:
	make -C $(KDIR) M=$(PWD) modules

compile_commands.json:
	make -C $(KDIR) M=$(PWD) compile_commands.json

.PHONY: clean
clean:
	make -C $(KDIR) M=$(PWD) clean

.PHONY: checkpatch
checkpatch:
	make clean
	$(KDIR)/scripts/checkpatch.pl --no-tree -f --max-line-length=95 *.[ch]
