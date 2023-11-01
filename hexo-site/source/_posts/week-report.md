---
title: 付杰周报-20231028
date: 2023-03-08 14:45:34
tags: RISC-V
---

[TOC]

# 取指Ping Pong FIFO设计

## 问题描述

> IF Stage的FIFO在遇到指令重定向到时候，会导致冲刷掉其内部所有的预取指令，是很大的浪费

![image-20231028053834305](../../../../../../Pictures/Typora/image-20231028053834305.png)

1. 由于FIFO容量是5\*16，当所有指令都是压缩指令的时候，指令的冲刷会导致至多4条有效指令被浪费了

2. 单一FIFO的重定向逻辑如下:

   ![image-20231028073735678](../../../../../../Pictures/Typora/image-20231028073735678.png)

   - cycle0发生重定向
   - cycle1冲刷掉FIFO里所有的指令，并且从I-Memory里按照sequential_pc取出指令放到FIFO头部(该指令在流水线上的指令可能会被Hazard Unit控制冲刷掉)
   - cycle2按照redirection_pc从I-Memory里取出指令放到FIFO头部

## 改进设计

> 核心思想是：尽可能保存预取指令，避免浪费

### Ping Pong FIFO(PPF)思想

1. 采用2个FIFO取指队列，当重定向产生导致FIFO需要冲刷的时候，暂时不要冲刷FIFO；
   将指令暂时写入到另一个空闲的FIFO当中
2. 重定向返回的时候，从之前的FIFO的去指令，利用预取的指令

### 硬件实现

1. 硬件上为了支持PPF需要实现的功能有:

   - 额外的FIFO(5\*16bits寄存器)
   - 指令PC计算逻辑 & 旧指令选择逻辑
     - 重定向发生的时候，提前根据重定向类型，将重定向返回时的指令对应的pc存储起来，
       那么在重定向返回的时候，可以通过该寄存器的值快速得到指令对应的pc
     - 旧指令选择逻辑需要根据重定向
   - ping pong FIFO控制逻辑

     - 使用free[1:0]寄存器来表示ping pong FIFO里的内容是否有效
     - **重定向发生的时候**: 如果一个FIFO里的内容是无效的，则可以在重定向发生的时候，将新的指令写入到该FIFO里
     - **重定向发生的时候**，假如另一个FIFO空闲，其free寄存器对应字段拉低
     - **重定向返回的时候**，将当前FIFO对应的free寄存器位拉高

2. 硬件实现

   ![image-20231028074746545](../../../../../../Pictures/Typora/image-20231028074746545.png)

   - 2个5\*16的FIFO
   - pc_instr寄存器用于记录FIFO头部的指令对应的pc
   - free寄存器用于记录FIFO是否空闲，假如FIFO内部没有有效数据，则FIFO空闲
   - waiting_for寄存器记录FIFO内指令对应内容，用于判断重定向的返回

3. 举例说明

   ![image-20231028080113030](../../../../../../Pictures/Typora/image-20231028080113030.png)

   - 针对SBP导致的重定向，其waing_for寄存器应该是EXE Stage的PTNT信号

     - 若下一个cycle没有得到该信号，则表示重定向正确，当前FIFO里的指令确实是无效指令，则free当前FIFO

   - 针对中断&异常，会进入到中断服务程序去处理

     - 如果ISR指令很多，则mret指令迟迟不能遇到->waiting_for信号迟迟不能拉高

     - 此时一个FIFO相当于一直都是not free的，此时PPF退化成单一FIFO

     - 设置一个Timer计数器，当Timer达到一定值的时候，丢弃FIFO里的内容

       > 有利于分支指令、不利于ISR的返回

       ![image-20231028081111125](../../../../../../Pictures/Typora/image-20231028081111125.png)

## 性能分析

TODO: add math analysis
TODO: 每种指令的比例，每种类型的指令的影响单独分析，列出参考的文献

1. RISC-V中各种分支指令的比例:
   - JAL：一定跳转，且跳转地址可以通过pc+offset得到, 占比
   - JALR：一定跳转，且跳转地址需要将pc+register才可以得到, 占比
   - Branch(条件分支指令): 跳转与否取决于跟寄存器值的比较, 占比
   - ecall
   - mret
   - TODO: 增加占比，编译所有的benchmark里面的指令，得到反汇编文件里的指令占比
   - TODO: 也可以用xyz等符号来表示

### 指令应用场景

1. 说明函数调用会涉及到什么指令
2. 函数调用的时候会用到哪些指令（RISC-V各个分支指令的主要用法）

### 访存减少

1. 针对JAL指令，由于JAL 100%跳转，因此JAL指令后面预取的指令，肯定都是应该被冲刷掉的指令
2. 结论：~~针对JAL指令，采用singel FIFO跟dual FIFO，性能是一样的~~
3. 结论：对于JAL指令，如果采用dual FIFO保存预取的指令，则返回的时候可以利用预取的指令

TODO: add Pic 1

### 中断返回加速

# RISC-V Verification

> TODO: quite hard

1. TODO: sv
2. TODO: UVM
   - testcase
   - checker
3. 中断如何测试

# 综合结果

TODO: 时钟约束在哪里设置？

1. 综合的时候，不支持`===`操作

   ![](https://s2.loli.net/2023/11/01/jd1G5b9QyfJSKuz.png)

   TODO: add picture of `===`

2. 如何将memory替换成库里的文件: 之前老师给了库里的内存模块，后面写代码前仿的时候实际上用的是32\*1024的寄存器组
   ![](https://s2.loli.net/2023/11/01/zpwtdjN5nL6kFDm.png)
   在综合的时候，会提示如下内容
   ![](https://s2.loli.net/2023/11/01/voIgC8Bd17SUcTD.png)
   感觉综合的时候，所有寄存器都会提示`will be removed`，如下所示：
   ![](https://s2.loli.net/2023/11/01/iqnwXAbZa7GFtJg.png)

3. mcu面积
   ![](https://s2.loli.net/2023/11/01/vn7sCHbeyw8lKTa.png)

4. mcu功耗参考
   ![](https://s2.loli.net/2023/11/01/1TpoBeOgbcz3SY6.png)

5. mcu频率

# 参考资料

1. [基本的时序路径约束](https://cloud.tencent.com/developer/article/1653346)
