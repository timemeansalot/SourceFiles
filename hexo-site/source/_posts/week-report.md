---
title: 付杰周报-20231028
date: 2023-03-08 14:45:34
tags: RISC-V
---

[TOC]

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

# 自定义指令

![](https://s2.loli.net/2024/01/05/AzK5bBO8JF9ixHN.png)

> PS: Q: does ACC has shared bus structure to allow data transfer between ACC in T502?

1. write data to DMA config register
   - not much better than SW
2. move data between ACC, MCU as data path center:
   - MCU has a DMA module used for move data between ACC
   - This DMA module is composed of a FIFO
   - use customized instruction to config the DMA, R-Type:
     - rd: target ACC
     - src1: source ACC
     - src2: base and offset?

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

## Spyglass
