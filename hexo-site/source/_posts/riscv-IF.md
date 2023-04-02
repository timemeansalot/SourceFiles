---
title: RISCV 5级流水线取指级设计
date: 2023-03-27 10:57:57
tags: RISCV
---

RISCV 5 级流水线“取指”部分设计

1. 开源项目中“取指级”参考
2. 本项目“取指级”设计
<!--more-->

[TOC]

> 取指级需要处理的 2 个关键问题：1. PC 重定向 2. 指令对齐

## 开源项目取指参考

### 果壳

![nutshell_if](/Users/fujie/Pictures/typora/IF/nutshell_if.jpg)

1. 取指

   > 功能: 取指、更新 PC、指令对齐

   1. 根据 BP 的结果更新 PC
   2. 根据 PC 从`I$`中取数据，一次取 1 个 Cache Line(64bits 的数据
   3. 取指数据会被压入到指令对齐缓冲`IAB`，由 IAB 识别指令边界，得到指令

2. 分支预测器

   > 功能：三种类型的混合预测器

   1. 默认 PC+8
   2. BTB：512 entry，每个 entry 的数据如下图所示： -> JAL, JALR
      <img src="/Users/fujie/Pictures/typora/image-20230329100629799.png" alt="image-20230329100629799" style="zoom:67%;" />
   3. RAS：16 entry, 每个 entry 是 32bit 的 PC 地址 -> call, ret
   4. PHT: 512entry，每个 entry 是 2bit 预测器-> 处理条件分支指令(B-Type Instructions)

   > RAS 和 PHT 用<u>同步写异步读的寄存器</u>来实现, BTB 由于面积较大而通过<u>快速 SRAM</u> 来实现, 因此在访问前者时需要将取指 PC 缓存一拍.

3. CSR

   > 功能：判断 trap 发生、类型，传递给 WB

   1. CSR 单元处于 EXE 级，配合 CSR Register 实现权限控制及对 trap 处理
   2. Load Store 指令由 LSU 判断是否发生 exception，如果发生则由 LSU 将 excption 信息转发给 CSR 单元  
      果壳项目中：<u>EXE 级和 MEM 级被合并成了同一个</u>, EXE 后面直接跟的是 WB, 其 EXE 可能占用多个周期
   3. 其他指令在 decode 阶段就可以判断其 exception，exception 信息由 ID 经过流水线传递给 CSR 单元

4. WB

   > 功能：**传递重定向 PC** 及写回数据(writ back data)

   1. 重定向(redirection)：当 EXE 发现 BP 错误、CSR 判断 trap 发生的时候，触发重定向 -> 发送正确的 PC 给 IF
   2. 写回：将需要写回给 rd 的数据传回给 ISU，由 ISU 写入到 Register File

### 蜂鸟低功耗处理器核

<img src="/Users/fujie/Pictures/typora/IF/EBirt2StagePipeline.jpg" alt="EBirt2StagePipeline" style="zoom:50%;" />

1. 采用 ITCM
   - 蜂鸟采用 64bits 的 SRAM 作为 ITCM
   - 面积更加紧凑、顺序读取 64bits 的数据，其只需要 1 次动态功耗
2. 指令对齐:

   - leftover buffer,  
     蜂鸟采用 leftover buffer 来实现指令对齐，存储指令的高 16bits 到 leftover buffer：连续取指的时候，1 个 cycle 可以解决指令不对齐问题；非连续取指的时候，必须 2 个 cycle 才可以解决指令不对齐问题
     <img src="/Users/fujie/Pictures/typora/IF/leftoverBuffer.svg" alt="leftoverBuffer" style="zoom: 67%;" />
   - 2 back SRAM

     <img src="/Users/fujie/Pictures/typora/IF/2bankSram.svg" alt="2bankSram" style="zoom: 70%;" />

3. 蜂鸟支持 C 压缩指令集，因此它需要考虑指令对齐的问题(16bit 和 32bit 的指令混合存储在 I-memory 中)
   - RISCV 指令格式：32bit 的指令，其低 2bit 一定是 11；否则是 16bit 的指令
   - 如果只支持 32bits 的指令，则可以默认取指地址低 2bit 为 00（默认指令恒 4B 对齐）
4. 蜂鸟 EXE 级在遇到<u>分支预测错误、trap</u>的时候，都会触发重定向，会返回给 IF
   <img src="/Users/fujie/Pictures/typora/IF/ebirtCommit.jpg" alt="ebirtCommit" style="zoom:50%;" />

   - BP 错误：条件跳转指令的结果由 EXE 级的 ALU 计算得到
   - CSR: 蜂鸟只支持机器模式、没有虚拟地址不存在 page 缺失相关的异常

   > 中断和异常的实现时处理器实现非常关键的一部分，同时也是最为烦琐的一部分。得益 于 RISC-V 架构对于中断和异常机制的简单定义，蜂鸟 E200 对其进行硬件实现的代价很小。 即便如此，异常和中断相关的源代码相比其他模块而言，仍然非常细琐繁杂

<div STYLE="page-break-after: always;"></div>
## 本项目取指部分设计

![pipeline_scratch_detectInIF](/Users/fujie/Pictures/typora/IF/pipeline_scratch_detectInIF.svg)

> 取指阶段主要需要解决的问题是：<u>PC 重定向、指令对齐</u>

### PC 重定向

1. IF 没有分支预测，PC+=4  
   IF 阶段会判断指令是否是压缩指令，如果是压缩指令，则下次 PC+2，否则下次 PC+4  
   IF 阶段有 `prefetch buffer` 用于提前一个周期存储指令，这样流水线从 stall 恢复的时候，就不用等待 1cycle 从 I-memory 中取对应指令了

   > 32bits 的指令`instr[1:0]==11`

   **重定向发生的时候，I-Mem 直接采用重定向的 PC 作为取值地址**，可以避免 1 个 cycle 的 penalty

2. ID 采用静态分支预测，如果解码判断是分支指令，会计算 target PC  
   不会冲刷流水线
   ![redirection_ID](/Users/fujie/Pictures/typora/IF/redirection_ID.svg)
3. EXE 的 ALU 会对条件分支指令的结果进行判断，如果 ID 判断错误，EXE 会产生重定向 PC  
   冲刷 1 条流水线
   ![redirection_EXE](/Users/fujie/Pictures/typora/IF/redirection_EXE.svg)
4. MEM 的 CSR 单元会判断 trap 是否发生，如果发生 EXE 也会产生重定向 PC  
   冲刷 2 条流水线
   ![redirection_MEM](/Users/fujie/Pictures/typora/IF/redirection_MEM.svg)

<div STYLE="page-break-after: always;"></div>
### 指令对齐

1. 采用 2 bank SRAM 作为 I Memory 当指令地址没有 4B 对齐且指令是 32bit 指令时，跨 bank 读指令，并且完成指令拼接
2. 在支持压缩指令是，指令默认是 2B 对齐的($pc[0]==0$)
3. 如果$pc[1]==1$，需要读取 2 个 sram bank
4. 否如果$pc[1]\neq1$, 则只需要读取其中 1 个 sran bank
   - 如果$pc[2]==1$, 读 bank1
   - 如果$pc[2]==0$, 读 bank0

> PS: 在只支持 32bits 指令的处理器中，JALR 指令可能会计算得到的 PC 不是 4B 对齐的，但是在模拟器中测试该场景的时候，模拟器默认忽略了 PC 最低 2bits，导致不对齐的 PC 也可以从 I-memory 中读取指令，没有触发 exception.

![2bankSram](/Users/fujie/Pictures/typora/IF/2bankSram.svg)

<div STYLE="page-break-after: always;"></div>
## References

1. [Nutshell Documents](https://oscpu.github.io/NutShell-doc/%E6%B5%81%E6%B0%B4%E7%BA%BF/ifu.html)
2. [riscv-mcu/e203_hbirdv2](https://github.com/riscv-mcu/e203_hbirdv2)

## simulation platform

1. 各级流水线最基础的RTL代码，能够实现`ADD`指令的5级流水仿真
2. [代码仓库地址](https://github.com/timemeansalot/FAST_INTR_CPU/tree/master/src/rtl)

![ADD x7, x5, x6](https://s2.loli.net/2023/03/31/RvNAIQWx8HS1FLs.png)
![Waveform of ADD](https://s2.loli.net/2023/03/31/aqTs5JuvUCMfWcp.png)
