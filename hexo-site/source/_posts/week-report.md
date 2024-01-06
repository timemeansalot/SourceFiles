---
title: 付杰周报-20231028
date: 2023-03-08 14:45:34
tags: RISC-V
---

[TOC]

# AXI 自定义指令

## MCU配置ACC的两种方式

1. 通过MCU直接配置加速器的配置寄存器:
   - MCU从Config Memory读取配置信息
   - MCU将配置信息写入到加速器内部的配置寄存器
2. MCU通过自定义指令:
   - 自定义指令用于配置ACC的DMA控制器
     - 每一个ACC都有一个DMA
     - 从配置加速器寄存器的角度来看，DMA的效率更高、但是不够灵活
   - MCU用于配置ACC内部的DMA，增加DMA的灵活性
     - DMA搬运数据的起始地址
     - DMA搬运开始信号
   - 通过软件来执行自定义指令: 控制DMA -> 配置ACC
     - 对比LW指令没有明显的提升

## 加速器配置自定义指令集

![](https://s2.loli.net/2024/01/06/yufs1jWIL8m3v7J.png)

### 硬件支持

1. 修改MCU ID以译码该自定义指令
2. 在MCU增加DMA模块(可以看作是MCU的协处理器)
   - DMA模块内部支持Operation FIFO用于存储所有的DMA操作(避免MCU Stall)
   - Operation Format
     - Length: 24 bits
     - Acc1: 4 bits
     - Acc2: 4 bits

### 软件支持

1. 寻找可以自定义的编码空间
   ![](https://s2.loli.net/2024/01/06/pqHErjFiw2NIPTn.png)
   - 上图展示了目前RISC-V的opcode字段的占用情况
   - custom-0, custom-1是官方推荐的自定义的编码空间，因此我们自定义执行的opcode采用custom-0编码，为`0x0010111`
2. 自定义指令格式

   - 确定了opcode之后，还需要确定指令的编码格式，RISC-V一共有6种编码格式
     ![](https://s2.loli.net/2024/01/06/X7mDBRM9QF4526k.png)
   - 根据我们对该自定义指令的使用需求来确定编码格式:
     - `U-Type`是最适合的，但是`U-Type`在C程序里使用的时候不方便
     - `R-Type`在C程序里使用是最方便的

3. [支持自定义指令集采用**内联汇编**的方法](https://cloud.tencent.com/developer/article/1886469)，具体有如下两种:

   - 利用.insn模板进行编程，该[网页](https://sourceware.org/binutils/docs/as/RISC_002dV_002dFormats.html)展示了各种类型的RISC-V指令的insn编码格式
     ![](https://s2.loli.net/2024/01/06/7vtCFhK6sLZ9TGI.png)
   - 修改`binutils`让riscv gcc认识到这条指令

4. 在c程序中使用该自定义令  
   ![](https://s2.loli.net/2024/01/06/Fcn1d94imH7upgz.png)

# AXI Master测试

## 写一次

![image-20231229161242442](../../../../../../Pictures/Typora/image-20231229161242442.png)

## 读一次

![image-20231229230534620](../../../../../../Pictures/Typora/image-20231229230534620.png)

## 读多次

![image-20231229230044514](../../../../../../Pictures/Typora/image-20231229230044514.png)

## 读写交织

![image-20231229231439734](../../../../../../Pictures/Typora/image-20231229231439734.png)

## 读写错误

![image-20231230000039829](../../../../../../Pictures/Typora/image-20231230000039829.png)

## 读写stall

![image-20231230001138329](../../../../../../Pictures/Typora/image-20231230001138329.png)

# MCU未来工作计划

## MCU本身

1. 实现WFI
2. 跟ACC集成测试(耗时较久):
   - 搭建SoC
   - 测试MCU跟ACC的交互

## 加速器控制通路(ACC control path)

1. 实现自定义指令由MCU控制ACC的DMA控制器

## 加速器数据通路(ACC data path):

- ACC之间存在数据依赖，ACC的输出会被别的ACC使用
- 但是ACC之间彼此没有数据data path，体现为data path的不灵活
- Q: MCU可以作为连接所有ACC的数据中枢？将ACC的输出搬运到另一个ACC的输入？
