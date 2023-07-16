# STM32MP157 build

## Tips

### Decompile compiled device tree file

```sh
dtc -I dtb -O dts ../linux/arch/arm/boot/dts/st/stm32mp157a-dk1.dtb > compiled.dts
```

## Useful links

- <https://wiki.st.com/stm32mpu/wiki/STM32MP15_U-Boot>
  - <https://wiki.st.com/stm32mpu/wiki/U-Boot_overview>
  - <https://wiki.st.com/stm32mpu/wiki/How_to_configure_TF-A_FIP>
- <https://u-boot.readthedocs.io/en/latest/board/st/index.html>
  - <https://u-boot.readthedocs.io/en/latest/board/st/stm32mp1.html#build-procedure>
- Excellent build explanations, labs, etc for STM32MP1 <https://bootlin.com/training/embedded-linux/>
