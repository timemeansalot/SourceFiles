---
title: 付杰周报-20230815
date: 2023-03-08 14:45:34
tags: RISC-V
---

[TOC]

# Difftest接入中断

> 本周基本完成了中断部分的Difftest框架接入

## 对Spike修改部分

> 编译Spike时需要做的修改

1. 关闭Spike本身的中断
   ![turn off spike interrupt](https://s2.loli.net/2023/09/16/gHBntQA85JK1Uvz.png)
2. 在`diff_context`增加CSR寄存器相关的记录
   ![add_csr_in_difftest](https://s2.loli.net/2023/09/16/T1xRNPwdosJWcM5.png)
3. Difftest初始化时设置`mstatus`寄存器的初值
   ![set mstatus init value](https://s2.loli.net/2023/09/16/Bh2XOosbcfum9Tx.png)
   ![set mstatus to 0x1800](https://s2.loli.net/2023/09/16/PfS56cqjUVkNTYO.png)
4. 修改`diff_get_regs`函数，增加从spike获得内部CSR寄存器值的功能
   ![csr get](https://s2.loli.net/2023/09/16/dHG2npwm3LtMzyQ.png)
5. 修改`diff_set_regs`函数
   ![csr set](https://s2.loli.net/2023/09/16/gi51XY4ERH7mGnB.png)

> 完成上述修改之后对Spike进行编译得到`riscv32-spike-so`动态连接库，即可得到Spike的参考模型

## 对MCU修改部分

1. 通过DPI-C获得CSR寄存器的内容
   参考之前传递GPR到Difftest框架的过程（在`regfile.v`文件里通过DPI-C函数获取GRP的值），
   将`CSR.v`文件里的CSR寄存器的值传递到Difftest框架
   ```verilog
   // file: CSR.v
    import "DPI-C" function void set_csr_ptr(input logic [31:0] a []); // add DPI-C function
    initial set_csr_ptr(CSRs);
   ```
2. 将中断信号传到Difftest框架
   将PLIC传入的中断信号，连接到top，方便在Difftest框架里检测该信号

## 对Difftest框架修改部分

1. 在CPU_State里增加CSR的值

   > 之前比较CPU_State只比较了PC, GPR的值，现在需要再多比较CSR的值

   ![](https://s2.loli.net/2023/09/16/1OBrqEyoP6gV9TS.png)

2. 通过DPI-C获取MCU的CSR的值，并且保存到CPU_State里
   ![](https://s2.loli.net/2023/09/16/t36og17xFJ4uIrW.png)
3. 检测MCU中断，让Spike进入中断
   > 在Difftest检测MCU top的中断信号，信号为高时让Spike执行`diff_raise_intr`函数
4. 在Difftest里，比较MCU跟Spike状态的时候，额外需要比较CSR寄存器的状态

   > 目前只比较了MSTATUS, MTVEC, MEPC, MCAUSE四个寄存器的值，后续会增加对CSR.v里其他寄存器的比较

   ![compare csr](https://s2.loli.net/2023/09/16/KcpaZwEGVXyhUg4.png)

## 执行效果

![](https://s2.loli.net/2023/09/16/4695XSYnvFZ7kQD.png)

## 后续工作

1. 对Spike跟MCU的CSR初始化细节做进一步同步、通过Difftest对中断进行测试
2. tesecase构建
3. Q: 外部中断响应程序编写

# spyglass

1. 报告路径：
   1. `/home/fujie/Developer/verify/all.log`
   2. `/home/fujie/Developer/verify/all_v2.log`
   3. `/home/fujie/Developer/verify/all_v3.log`
   4. `/home/fujie/Developer/verify/vsrc/spyglass-1`
2. 报告最终截图
   ![image-20230916075420531](https://s2.loli.net/2023/09/16/gBqMJv4LtDoU3ZA.png)
   ![image-20230916075445019](https://s2.loli.net/2023/09/16/y8x2GEMcJFBgCz3.png)

[详细spyglass报告连接](https://timemeansalot.github.io/2023/09/15/spyglass/)
