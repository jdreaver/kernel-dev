# EC2 instance Terraform

This directory contains Terraform code for creating an EC2 instance for Linux kernel development.

## Running Terraform

Use the wrapper script `run.sh` to run terraform. e.g. `./run.sh plan` and `./run.sh apply`.

To change the instance type or instance state, use `-var` on the command line, e.g.:

```
$ ./run.sh apply -var="instance_type=c7i.48xlarge"
$ ./run.sh apply -var="instance_state=stopped"
```

You can also create a `.auto.tfvars` file, e.g.:

```
cat << EOF > overrides.auto.tfvars
instance_type = "c7i.48xlarge"
instance_state = "stopped"
EOF
```

## git setup

```sh
[laptop] $ ssh <remote-host>
[remote-host] $ git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
[laptop] # Do some development on your local tree
[laptop] $ git push ssh://<remote-host>/home/ubuntu/linux
```

## Kernel compilation on EC2

Stuff I had to install to compile:

```
$ sudo apt install build-essential libncurses-dev bison flex libssl-dev libelf-dev fakeroot dwarves
```

To compile, we use the host's kernel config:

```
$ cp -v /boot/config-$(uname -r) .config
$ scripts/config --disable SYSTEM_TRUSTED_KEYS --disable SYSTEM_REVOCATION_KEYS --set-str CONFIG_SYSTEM_TRUSTED_KEYS "" --set-str CONFIG_SYSTEM_REVOCATION_KEYS ""
$ yes "" | make oldconfig
$ make localmodconfig
$ make -j$(nproc)
```

Then install your kernel:

```
$ sudo make modules_install
$ sudo make install
```

You can then reboot and run `uname -a` to verify that your compiled kernel version is correct and you are therefore using your new kernel.
