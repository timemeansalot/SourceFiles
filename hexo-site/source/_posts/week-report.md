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

# 访存Leftover Buffer & Prefetch Buffer

## 问题描述

> 在访存的时候，若果存在lw+add这种的指令序列，由于没有MEM Stage->EXE Stage的bypass，则add指令需要等个1个cycle，造成1个bubble；
> 能否通过寄存器缓存D-Memory的内容，从而避免这个cycle的时间浪费？

## Leftover Buffer

### 思想

1. 将上次从D-Memory中取出的指令保存在寄存器里
2. 下次访问同样地址时，可以直接从该寄存器里读数

### 硬件实现

1. 硬件需要支持的功能：
   - 保存上次访存的内容
   - 访存是判断需要访问的地址对应的数据是否在Leftover buffer里
   - 在D-Memory跟Leftover Buffer里选择数据
2. 硬件实现:

![image-20231028083903963](../../../../../../Pictures/Typora/image-20231028083903963.png)

3. 优点:
   - 在特定情况下能解决lw stall问题
   - 并且可以避免D-Memory访问，节约功耗
4. 缺陷：
   - D-Memory访问很随机、因此不太可能访问到上次访问的数据
   - 增加了组合逻辑，增加了MEM Stage的周期

## Prefetch Buffer

### 思想

1. 每次取数据的时候，取64bits的数据，放入到一个Prefetch Buffer中
2. 在顺序访问D-Memory的时候，每个cycle都可以直接从Prefetch Buffer里取，并且更新Prefetch Buffer

### 硬件实现

1. 硬件需要支持的功能：

   - 每次取64bits数据
   - 存放预取的32bits数据，更新Prefetch Buffer
   - 在D-Memory跟Prefetch Buffer里选择数据

2. 硬件实现:

   ![image-20231028083851150](../../../../../../Pictures/Typora/image-20231028083851150.png)

3. 优点:在顺序访问D-Memory的内存下（例如数组遍历）时，Prefetch Buffer能够连续地发挥作用，解决lw stall

# 综合结果

1. read_file.tcl没有读进去文件

   ![image-20231027233257343](../../../../../../Pictures/Typora/image-20231027233257343.png)

   ![image-20231028091548022](../../../../../../Pictures/Typora/image-20231028091548022.png)

   ![image-20231027233040588](../../../../../../Pictures/Typora/image-20231027233040588.png)

   ![image-20231027233325726](../../../../../../Pictures/Typora/image-20231027233325726.png)

2. 手动读取文件

   ![image-20231028091655026](../../../../../../Pictures/Typora/image-20231028091655026.png)

3. 面积报告

   ![image-20231028091722792](../../../../../../Pictures/Typora/image-20231028091722792.png)

4. 功耗报告

   ![image-20231028092019593](../../../../../../Pictures/Typora/image-20231028092019593.png)

5. timing报告

   ![image-20231028092251194](../../../../../../Pictures/Typora/image-20231028092251194.png)
