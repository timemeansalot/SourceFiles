---
title: 付杰周报-20230701
date: 2023-03-08 14:45:34
tags: RISC-V
---

[TOC]

<!--more-->

- [ ] difftest makefile
- [ ] integrated difftest with mcu
- [ ] compile pass
- [ ] pass riscv-addi-test


# 查看波形
1. 更改`verilator.mk`文件里的`EMU_TRACE ?=1` 
2. 更改difftest中`emu.h`文件里添加如下宏定义`#define VM_TRACE 1`
3. 生成emu可执行文件后，调用emu的时候加上`--dump-wave`参数

参考[在difftest中查看仿真波形](https://github.com/OSCPU/ysyx/issues/11)
