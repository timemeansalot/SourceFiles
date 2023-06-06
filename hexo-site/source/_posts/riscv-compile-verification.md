---
title: RISC-V编译和验证
date: 2023-05-22 11:42:06
tags: RISC-V
---

riscv-tests 和 verification

<!--more-->

## TODO:

- [x] 避免名词错误，写完检查一遍

## Compile

### 工具链介绍(Tool Chain)

1. cc
2. objcopy
3. objdump
4. readelf
5. hexdump

### riscv-tests

1. 文件结构
2. 编译过程
   - 编译
   - objcopy 得到二进制文件
   - 使用脚本提取汇编代码部分，小端存放

### Makefile

1. 编译汇编测试文件(compile asembly test code)
2. 编译 RTL 文件(compile RTL DUT)
3. 单个测试
4. 回归测试
