---
title: 周报 2023-04-08
date: 2023-03-24 16:12:31
tags: RISCV
---

每周周报
<!--more-->
## 流水线取指部分设计

> 取指阶段主要需要解决的问题是：<u>PC 重定向、指令对齐</u>

### PC 重定向

1. IF 没有分支预测，PC+=2  
   <u>IF 阶段设置有一个 FIFO，最多存储 5\*16bits 的数据</u>，该 FIFO 的设置是因为我们不知道指令是 16bits 的还是 32bits 的。

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

### 指令对齐

![pipeline_scratch](/Users/fujie/Pictures/typora/IF/pipeline_scratch.svg)

1. FIFO 工作原理

   - FIFO 每次从 I-memory 读取 2x16 的数据
   - FIFO 中数据少于等于 3 的时候，FIFO 会从 I-memory 中读取数据，避免 underflow
   - FIFO 中数据大于 3 的时候，FIFO 会停止从 I-memory 中读取数据，避免 overflow
   - 当 ID 发现指令是 32bits 的时候，FIFO 头部 2 条数据会被 POP，FIFO 数据量-2
   - 当 ID 发现指令是 16bits 的时候，FIFO 头部 1 条数据会被 POP，FIFO 数据量-1

2. 采用 2 bank SRAM 作为 I-Memory, 两个 bank 的 SRAM 都是 16bits 的位宽，配合 FIFO 可以处理 32bits 指令不对齐的情况, 其工作原理如下：

   - 顺序读取: 顺序读取的时候不存在 PC 重定向，FIFO 不需要刷新

     1. 连续读 16bits 的指令：每次消耗 FIFO 中 1 条数据，读入 2 条数据到 FIFO，FIFO 数据量会逐步增加，当大于等于 3 的时候，FIFO 就不会继续从 I-memory 读取数据了
     2. 连续读 32bits 的指令：每次消耗 FIFO 中 2 条数据，读入 2 条数据到 FIFO，FIFO 数据量会保持恒定，FIFO 会继续从 I-memory 读取数据了
     3. 混合读取 16bits 和 32bits 的数据：上述两种方式的混合

   - PC 重定定向: 当发生 PC 重定向之后，FIFO 中现存的所有数据都是无效的，需要被刷新，并且下一个周期从 I-memory 中读出的指令也是无效的指令，也需要被丢弃; 在第二个周期读出的指令是重定向 PC 对应的指令，会被 PUSH 到 FIFO 中

> PS: 在只支持 32bits 指令的处理器中，JALR 指令可能会计算得到的 PC 不是 4B 对齐的，但是在模拟器中测试该场景的时候，模拟器默认忽略了 PC 最低 2bits，导致不对齐的 PC 也可以从 I-memory 中读取指令，没有触发 exception.

