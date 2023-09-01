---
title: 付杰周报-20230815
date: 2023-03-08 14:45:34
tags: RISC-V
---

[TOC]

# Benchmarks

- [ ] 原理, main function
- [ ] 一些开源项目是怎么做Coremark的
- [x] 源码（说明coremark跑分跟时间有关）
- [ ] IPC怎么计算，IPC其实更能展示处理器的性能

## 什么是基准测试
1. 目的：测试处理器运行的速度，从而评价处理器的性能
2. 影响因素：

## CoreMark

1. 基础介绍，[网站主页](https://www.eembc.org/coremark/)

   - CoreMark主要用于测试**嵌入式系统**的MCU跟CPU的性能，
     测试标准是在配置参数的组合下<u>单位时间内运行的CoreMark程序次数（单位：CoreMark/MHz）</u>，该数字值越大则说明测试的性能越好
   - 诞生于2009年，目的是作为Dhrystone的替代品（Dhrystone其实主要测试的是编译器的性能），
     为了避免编译器优化导致预先计算出结果，基准测试中的每个操作都会派生一个在编译时不可用的值。
   - CoreMark由C编写，包含的测试集主要有：列表处理（列表搜索、排序）、矩阵操作、状态机测试、CRC测试
   - CoreMark支持8 bits到64 bits的微处理器

2. MCU移植CoreMark：

   - 提供对printf的重映射支持：在测试完成之后，需要在中断打印测试分数
   - 提供一个足够精准的时间测量手段：CoreMark的评价标准是<u>单位时间内运行的CoreMark程序次数是</u>

3. source code
   - Microbench
     ![](https://s2.loli.net/2023/09/01/pVzw6s8hkRtgLMO.png)
   - Coremark
     ![](https://s2.loli.net/2023/09/01/9xMLikWUq7KjXFB.png)

## benchmark教程

![image-20230901102612409](https://s2.loli.net/2023/09/01/u7KWcOMmr4DFwq5.png)

![](https://s2.loli.net/2023/09/01/PgHoDackpyq5jlU.png)
Benchmark需要一个计算时间的手段，因为benchmark需要比较单位时间内执行程序的数量，从而给出一个评分

- [x] 增加代码说明timing

![](https://s2.loli.net/2023/09/01/wTJSViA4HcXqPD5.png)

> 你的中央处理器有多快？
> 当然，这是一个毫无意义的问题。处理器在一段时间内完成的工作量取决于很多因素，包括编译器(及其优化级别)、等待状态、可能窃取周期的后台活动(如 DMA)等等。然而，许多人试图建立基准，以使某种程度的比较成为可能。其中的原则是德里斯通。

> Scores are expressed as raw CoreMark, CoreMark/MHz (more interesting to me), and CoreMark/Core (for multi-core devices). There are two types of results - those submitted from vendors, and those certified by EEMBC's staff (for a charge).
> Results range from 0.03 CoreMark/MHz for a PIC18F97J60 to 168 for a Tilera TILEPro64 running 64 threads. The single-threaded max is 5.1 for a Fujitsu SPARK64V(8).
> But away from speed demons like Pentium-class or SPARC machines, the highest score is for Atmel's SAM4S16CAU - a Cortex M4 device - which notches in at 3.38 CoreMark/MHz. That beats out a lot of high-end devices.
> **Clock rates do matter**, and while the Intel Core i5 gets a score of 5.09 CoreMark/MHz, its raw result, at 2500 MHz, is 12715, or 6458 CoreMark/core. That thrashes the Atmel device which was tested to 21 MHz, where it netted 71 CoreMark.

Coremark的分数受访存的影响很大，因为从cache里读数据跟从flash里读数据花的时间是大大不同的，因此会严重影响时间、进而严重影响分数: The nearly-shocking news that the Core i5 is less than two times the score/MHz for a Cortex M4

## 在模拟器上跑分的时候，通过IPC更能体现性能

## Microbench

# Spyglass

# 参考文献

1. [Core Github](https://github.com/eembc/coremark)
2. [How fast is your CPU, By Jack Ganssle](http://www.ganssle.com/rants/coremark.html)
