---
title: 付杰周报-20230815
date: 2023-03-08 14:45:34
tags: RISC-V
---

[TOC]

# Benchmarks

- [ ] 原理
- [ ] 一些开源项目是怎么做Coremark的
- [ ] 源码（说明coremark跑分跟时间有关）
- [ ] IPC怎么计算，IPC其实更能展示处理器的性能

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

## Microbench

# Spyglass

# 参考文献

1. [Core Github](https://github.com/eembc/coremark)
