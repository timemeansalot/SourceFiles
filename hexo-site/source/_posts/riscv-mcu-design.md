---
title: RISC-V处理器设计
date: 2023-05-04 17:02:03
tags: RISC-V
---

RISC-V 处理器设计：

1. 处理器核设计: 5 级流水线处理器
2. SoC 设计：软件、调试
<!--more-->

## 5 级流水线处理器核设计

1. IF(instruction fetch)
2. ID(instruction decode)
   - [RISC-V 压缩指令集](https://timemeansalot.github.io/2023/04/10/RISC-V-compressISA/)
   - [RISC-V 译码级设计](https://timemeansalot.github.io/2023/04/04/riscv-ID/)
   - [RISC-V指令集介绍](https://timemeansalot.github.io/2023/03/07/riscv-isa/)
3. EXE(execution)
   - [RISC-V 执行级设计](https://timemeansalot.github.io/2023/04/04/riscv-EXE/)
4. MEM(memory access)
   - [RISC-V 访存级](https://timemeansalot.github.io/2023/04/05/riscv-MEM/)
   - [RISC-V 异常和中断](https://timemeansalot.github.io/2023/03/23/riscv-trap/)
5. WB(write back)
   - [RISC-V 写回级](https://timemeansalot.github.io/2023/04/04/riscv-WB/)

## 参考资料

1. [tinyriscv](https://liangkangnan.gitee.io/2020/04/29/%E4%BB%8E%E9%9B%B6%E5%BC%80%E5%A7%8B%E5%86%99RISC-V%E5%A4%84%E7%90%86%E5%99%A8/): 从零开始写 RISC-V 处理器，介绍了 3 级流水线的 RISC-V 处理器核、其配套的软件、调试以及 FPGA 移植
2. [Hummingbirdv2 E203 Core and SoC](https://github.com/riscv-mcu/e203_hbird)：蜂鸟 E203 两级流水线 MCU，手把手教你设计一个 RISC-V 处理器
3. [Nutshell](https://github.com/OSCPU/NutShell)：国科大的顺序流水线处理器核
