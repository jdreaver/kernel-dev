# STM32MP157 build

## Useful links

- <https://wiki.st.com/stm32mpu/wiki/STM32MP15_U-Boot>
  - <https://wiki.st.com/stm32mpu/wiki/U-Boot_overview>
  - <https://wiki.st.com/stm32mpu/wiki/How_to_configure_TF-A_FIP>
- <https://u-boot.readthedocs.io/en/latest/board/st/index.html>
  - <https://u-boot.readthedocs.io/en/latest/board/st/stm32mp1.html#build-procedure>
- Excellent build explanations, labs, etc for STM32MP1 <https://bootlin.com/training/embedded-linux/>

## TODO

```
env set ipaddr 10.42.0.100
env set serverip 10.42.0.1
env set bootcmd 'tftp 0xc2000000 zImage; tftp 0xc4000000 stm32mp157a-dk1.dtb; bootz 0xc2000000 - 0xc4000000'
env set bootargs ${bootargs} root=/dev/nfs ip=10.42.0.100 nfsroot=10.42.0.1:/nfs-export/rootfs,nfsvers=3,tcp rw
```
