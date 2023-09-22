---
title: 付杰周报-20230815
date: 2023-03-08 14:45:34
tags: RISC-V
---

[TOC]

# 构建中断testcase

## 初始化系统

1. 初始化所有的gpr，避免difftest报错
2. 设置`mtvec`的值:
   - `mtvec`存放<u>中断处理程序的</u>地址
   - 当中断(interrupt)异常(exception)发生的时候，
     程序会在硬件控制下跳转到`mtvec`，即`pc=csr[mtvec]`
3. 设置栈空间：中断处理程序需要保存上下文到栈里，栈大小设置为1024
4. 跳转到测试程序：系统基本设置好了之后，就跳转到测试程序处执行`jal _test`

## 准备中断处理程序

2. 中断处理程序(软件)，主要做了如下的工作

   - 保存系统状态，即保存重要的csr寄存器的值到栈上
   - 将gpr进行压栈，避免gpr被trap_handler程序覆盖
   - 跳转到trap_handler: `jal trap_handler`
   - 将grp出栈
   - 从栈里恢复csr寄存器的值
   - 调用mret返回

   > ps: ecall->硬件修改csr寄存器的值，如mstatus, mepc, `pc=csr[mtvec]`
   > 进入到中断处理程序
   > mret->硬件修改csr寄存器的值，`pc=csr[mepc]`

3. trap_handler
   顾名思义，是用于处理不同的中断、异常的程序，本质上是一段程序，
   可以由汇编编写、也可以由c编写。

   - 在testcase里，trap_handler只是一个在中断处理程序中的**跳转地址**，
   - 通过`jal trap_handler`进入具体的中断处理代码，通过`ret`返回到中断处理程序
     剩余部分

## 测试程序

一段正常的测试程序:

为了测试中断处理程序，有如下两种途径：

1. 软件中断(YSYX的例子，其中断处理过程如下)：

   - 初始化系统，跳转到测试程序第一条指令处执行
   - 测试程序有一条`ecall`指令
   - ecall指令触发软件中断，pc跳转到mepc位置，进入到中断处理程序
   - 中断处理程序处理器状态、保存上下文
   - 进入到trap_handler，具体针对中断进行处理
   - trap_handler调用ret返回
   - 中断能处理程序恢复处理器状态、恢复上下文
   - 调用mret，pc跳转到之前程序的位置执行

2. 外部中断(测试plic):
   跟软件中断的过程很像，不同之处在于pc跳转到mepc不是因为ecall指令，而是因为
   plic发过来了一个中断

> PS：需要注意的是，由于多了初始化系统的部分，所以`0x80000000`不是存放测试程序第一条指令，
> 测试程序第一条指令在初始化完成之后通过`jal`跳转

3. 代码分析
   testcase主要包含两个代码文件:
   - trap.S: 主要包括<u>系统初始化</u>，<u>中断处理程序</u>
   - test.S: 主要包括<u>测试程序</u>跟<u>trap_handler</u>

   > 代码在interrupt分支下: [FAST_INTR_CPU/src/verification/riscvtest/interrupt/](https://github.com/ChipDesign/FAST_INTR_CPU/tree/interrupt/src/verification/riscvtest/interrupt)
## 运行截图

目前对软件中断进行了测试，经过测试证明testcase代码逻辑能够按照预期运行到`_test`里的ebreak指令，从而退出difftest;
各个函数的执行顺序如下图所示:
![](https://s2.loli.net/2023/09/23/QUaBvA7zX6EweKJ.png)

运行截图如下：
![](https://s2.loli.net/2023/09/23/E4N6C1UwifdZ7Oz.png)

目前中断测试存在下面一些问题：

1. 目前对于`ecall`的指令功能没有实现完全，导致`csr[mepc]=pc`功能没有实现，进而导致`mret`指令不能正常运行
2. 对于其他csr寄存器的功能正确性，需要进一步测试，现在difftest发现很多寄存器的值都对不上，需要找到哪里实现有问题

# 参考资料

1. [YSYX PA3](https://ysyx.oscc.cc/docs/ics-pa/3.2.html#%E8%AE%BE%E7%BD%AE%E5%BC%82%E5%B8%B8%E5%85%A5%E5%8F%A3%E5%9C%B0%E5%9D%80)
2. [riscv-operating-system-mooc](https://gitee.com/unicornx/riscv-operating-system-mooc?_from=gitee_search)

```

```
