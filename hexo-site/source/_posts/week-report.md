---
title: 付杰周报-20230815
date: 2023-03-08 14:45:34
tags: RISC-V
---

[TOC]

# Benchmarks

## 什么是基准测试

![image-20230901102612409](https://s2.loli.net/2023/09/01/u7KWcOMmr4DFwq5.png)

1. 目的：测试处理器运行的速度，从而评价处理器的性能
2. 影响处理器单位时间内工作的因素有很多，如：编译器性能、访存的时间、应用的种类
3. 基准测试：精心设计的一套程序用于覆盖一些通用的计算场景，如列表操作、矩阵计算等
4. 测试原理：比较处理器完成基准测试的时间，时间越快越好

## CoreMark

网站主页](https://www.eembc.org/coremark/)

- CoreMark主要用于测试**嵌入式系统**的MCU跟CPU的性能，
  测试标准是在配置参数的组合下<u>单位时间内运行的CoreMark程序次数（单位：CoreMark/MHz）</u>，该数字值越大则说明测试的性能越好
- 诞生于2009年，目的是作为Dhrystone的替代品（Dhrystone其实主要测试的是编译器的性能），
  为了避免编译器优化导致预先计算出结果，基准测试中的每个操作都会派生一个在编译时不可用的值。
- CoreMark由C编写，包含的测试集主要有：列表处理（列表搜索、排序）、矩阵操作、状态机测试、CRC测试
- CoreMark支持8 bits到64 bits的微处理器

## Microbench

> 每个benchmark都记录以`REF_CPU`为基础测得的运行时间微秒数。每个benchmark的评分是相对于`REF_CPU`的运行速度，与基准处理器一样快的得分为`REF_SCORE=100000`。
> 所有benchmark的平均得分是整体得分。

1. 需要实现TRM和IOE的API。
2. 在IOE的全部实现均留空的情况下仍可运行。如果有正确实现的`AM_TIMER_UPTIME`，可以输出正确的统计时间。若这个功能没有实现(返回`0`)，仍可进行正确性测试。
3. 使用`putch(ch)`输出。
4. 堆区`heap`必须初始化(堆区可为空)。如果`heap.start == heap.end`，即分配了空的堆区，只能运行不使用堆区的测试程序。每个基准程序会预先指定堆区的大小，堆区不足的基准程序将被忽略。
5. 主要包含的测试程序：

   | 名称  | 描述                                        | ref堆区使用 | huge堆区使用 |
   | ----- | ------------------------------------------- | ----------- | ------------ |
   | qsort | 快速排序随机整数数组                        | 640KB       | 16MB         |
   | queen | 位运算实现的n皇后问题                       | 0           | 0            |
   | bf    | Brainf\*\*k解释器，快速排序输入的字符串     | 32KB        | 32KB         |
   | fib   | Fibonacci数列f(n)=f(n-1)+…+f(n-m)的矩阵求解 | 256KB       | 2MB          |
   | sieve | Eratosthenes筛法求素数                      | 2MB         | 10MB         |
   | 15pz  | A\*算法求解4x4数码问题                      | 2MB         | 64MB         |
   | dinic | Dinic算法求解二分图最大流                   | 680KB       | 2MB          |
   | lzip  | Lzip数据压缩                                | 4MB         | 64MB         |
   | ssort | Skew算法后缀排序                            | 4MB         | 64MB         |
   | md5   | 计算长随机字符串的MD5校验和                 | 10MB        | 64MB         |

## MCU移植CoreMark：

- 提供对printf的重映射支持：在测试完成之后，需要在中断打印测试分数
- 提供一个足够精准的时间测量手段：CoreMark的评价标准是<u>单位时间内运行的CoreMark程序次数是</u>

![](https://s2.loli.net/2023/09/01/PgHoDackpyq5jlU.png)

## Source Code

- Microbench
  ![](https://s2.loli.net/2023/09/01/pVzw6s8hkRtgLMO.png)
- Coremark
  ![](https://s2.loli.net/2023/09/01/9xMLikWUq7KjXFB.png)

# Benchmark vs CPI

## 影响Benchmark得分的因素

Benchmark的跑分需要计算一个关键的数据，即**程序的运行时间**，处理器微架构一模一样的情况下：

1.  模拟器上跑benchmark：将处理器编译成模拟器在x86主机上运行，该模拟器运行benchmark的时间，受**x86主机性能**的影响
    ![](https://s2.loli.net/2023/09/01/JRcsUmGWtadbI4p.png)
2.  在FPGA上跑benchmark：将RTL移植到FPGA上运行benchmark程序，运行的时间受**频率**的影响
    ![](https://s2.loli.net/2023/09/01/wTJSViA4HcXqPD5.png)
    - 如上图所示：coremark官网上跑分排行榜里的处理器得分，会给出`CoreMark`跟`Coremark/MHz`，其实后者更有意义
    - 例如：Intel Core I5在2500MHz下的CoreMark得分为12725分、Atmel的设备在21MHz下的得分为71分，因此频率对于CoreMark得分影响很大
    - 开源项目如蜂鸟以及Coremark官网上的跑分排行榜，都是在硬件上得出来的，而且会附上频率
3.  除此之外
    - Benchmarks得分受访存的影响很大，访问慢速存储器会导致程序的运行时间大大增加，从而严重降低得分
    - Benchmarks不能完整测试处理器所有的性能，例如尽管Intel I5相比Arm M4有更好的浮点运算能力，但是其在Benchmarks里的`CoreMark/MHz`得分却比后者低了2倍

## 在模拟器上跑分的时候，通过CPI更能体现性能

1. 在处理器微架构确定的情况下，处理器运行同一套benchmark的CPI是恒定的
2. CPI(Clock Per Instructions)在MCU上如何计算?
   - 在TOP里设置两个计数器: `cycle_register`, `instruction_register`
   - 每个时钟上升沿都将cycle_register加一
   - 在一条指令提交的时候才将instruction_register加一，被flush的指令不会导致instruction_register加一
   - 在MCU上跑benchmark程序，结束后即可计算CPI: `CPI=cycle_register/instruction_register`

# Spyglass

# 参考文献

1. [Core Github](https://github.com/eembc/coremark)
2. [How fast is your CPU, By Jack Ganssle](http://www.ganssle.com/rants/coremark.html)
