---
title: RISCV执行级设计
date: 2023-04-04 15:38:11
tags: RISCV
---

![ALU](https://s2.loli.net/2023/04/10/xW4djv3JGEB2zyg.png)
RISC-V 执行级设计

<!--more-->

# 32 Shifter Design

[Github 仓库地址](https://github.com/ChipDesign/FAST_INTR_CPU/tree/main/src/rtl)
![](https://s2.loli.net/2023/03/10/CtRza3lUdwKHB7y.png)

RV-32IM 需要实现的移位操作不包括循环移位，只包括：<u>逻辑左移</u>、<u>逻辑右移</u>和<u>算数右移</u>。  
若使用**移位寄存器**来实现移位，每个周期移位是固定的，因此需要多个周期才可以完成移位操作。
![shift01](https://s2.loli.net/2023/03/11/D6uWOnjrogmNsvk.png)
上图是一个由 4 个 D 触发器构成的简单向右移位寄存器，数据从移位寄存器的左端输入，每个触发器的内容在时钟的上升沿将数据传到下一个触发器。

在 ALU 种需要多数据进行多位移位的操作，采用移位寄存器一次只能移动移位，效率太低；**桶形移位器**采用组合逻辑的方式来实现同时移动多位，在效率上优势极大。因此桶形移位器常被用在于 ALU 中实现移位。

![barrlShifter](https://s2.loli.net/2023/03/11/wSgedMkjVhoq1A6.jpg)

1. din：待移位待输入数据
2. shift: 移位待位数，有效范围为$[0, \log N-1]$
3. Left/Right: 左移或者右移
4. Arith/Logic：算数右移/逻辑右移
5. dout：移位后的数据

以 4bits din 的 barrlShifter 为例，其 Schematic 如下：

![barrlShift4bits](https://s2.loli.net/2023/03/11/Wv3ZMVen9fEbXpY.jpg)

- 对于 Nbits 的输入数据，其需要的选择器一共有$\log N$层，每一层共有 N 个选择器，其中第一层选择是否移位 1bit，第二层选择是否移位 2bits，...。
- 对每一个 4 选 1 选择器，其 00 和 10 输入选择未移位后的数据；01 选择右移的数据、11 选择左移的数据。
