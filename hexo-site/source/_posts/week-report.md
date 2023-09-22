---
title: 付杰周报-20230815
date: 2023-03-08 14:45:34
tags: RISC-V
---

[TOC]

- [x] 阅读ysyx代码
- [ ] TODO: 报告里每部分需要增加ysyx代码说明
- [ ] TODO: 参考mooc的代码

# 异常响应机制

1. csr寄存器、重要的csr寄存器: {pc, gpr} -> {pc, gpr, csr}
2. csr指令: 已经实现
3. trap可以理解为执行了一条虚拟的特殊指令`raise_intr`，该指令的功能是:
   ```bash
       CSR[mepc] <- PC
       CSR[mcause] <- 一个描述失败原因的号码
       PC <- CSR[mtvec]
   ```
   当外部中断、内部中断发生的时候，这条虚拟指令将会被执行
4. 通过`ecall`指令自陷，从用户态进入到操作系统态

- [ ] TODO: 用drawio画异常处理机制的图 `ecall or outside interrupt -> mret`

# 上下文管理

1. 栈空间

# 进入异常处理函数(软件)

## 软件对gpr进行保存

1. 原因：异常处理器程序本身执行的过程中也会使用到gpr，如果不对gpr进行保存；
   则gpr的内容会被覆盖且无法恢复.
2. riscv可以通过`sw`指令将gpr的值存储到栈stack上(stack本上在data-memory上)
   - Q：stack在data-memory哪个位置？
   - Q：stack容量多大？
   - Q：stack如何影响汇编文件 testcase？
   - Q：stack跟链接脚本`xx.ld`的关系？

## 对状态进行保存

1. pc和处理器状态:
   - 主要是`mepc`跟`mstatus`寄存器
   - 硬件会自动更新二者的值
   - 需要软件将其内容写出到stack <- TODO: check this
2. 异常号:
   - 主要是`mcause`寄存器
   - 硬件会自动更新二者的值
   - 需要软件将其内容写出到stack <- TODO: check this

> 上述内容构成了完整的上下文信息、异常处理的时候需要根据上述内容进行处理、恢复的时候也需要上述信息

# <u>实现</u>异常处理函数

# 恢复上下文
