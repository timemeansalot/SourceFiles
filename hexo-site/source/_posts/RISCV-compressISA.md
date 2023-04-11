---
title: RISC-V压缩指令集
date: 2023-04-10 19:58:24
tags: RISCV
---

![RV-32C](https://s2.loli.net/2023/04/10/C73opKyZbMJrktW.png)
RISC-V 压缩指令集学习笔记

<!--more-->

## RV-32C

> Typically, 50%–60% of the RISC-V instructions in a program can be replaced with RVC instructions, resulting in a 25%–30% code-size reduction.

1. 什么时候可以压缩
   1. imm, offset 很小的时候
   2. register 是 x0, x1 或者 x2
   3. register 是常用的那 8 个
   4. rs1=rd
2. RV-32C 可以跟其他指令集搭配使用，不能单独使用；启用 RV-32C 之后，32bits 的指令和 16bits 的指令是混合存放的，并且此时不会有 `instruction-address-misaligned exceptions`
3. RV-32C 可以在 ID 的时候很容易地被恢复成 RV-32I
