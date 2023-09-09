---
title: DSP基准测试
date: 2023-09-08 13:14:32
tags: DSP
---

[TOC]

<!--more-->

# DSP Benchmark

## 什么是DSP Benchmark

1.  定义: Benchmark是一个用于<u>定量评估</u>计算机<u>软硬件资源</u>的程序
2.  作用: 人们通过选择合适的Benchmark可以判断一个系统是否符合设计预期，具体为：
    - **比较**：通过Benchmark可以比较处理器之间的性能差距，从而选择更好的处理器
    - **量化**：定量地评估处理器的*速度、功耗、内存占用*等数据，从而<u>判断一个DSP平台是否符合特定的用户应用</u>
3.  DSP对比CPU的不同之处:

    1.  更快地乘累加(Fast Multiply-Accumlate)：
        - 乘累加在很多计算里都会使用，例如数字滤波、相关性、傅里叶变换等
        - DSP内部有很多的乘法及累加器，从而使得一条DSP指令就可以完成乘累加的计算
    2.  多访存架构(Multiple-Access Memory Architecture)
        - 一次计算出多个方寸地址
        - 并行地完成取指令、取操作数、写回的操作
    3.  特殊寻址方式(Specialized Addressing Modes): 通过特殊的地址产生方式，从而更好的处理数据数组
    4.  特殊执行控制(Specialized Execution Control):
        - DSP的计算很多都是**重复地在某个循环内做计算**
        - DSP针对loop做了特殊的优化
    5.  外设跟IO控制(Peripherals and Input/Output Control): 倾向于集成一些简单的片上外设及IO

    > DSP对比CPU的不同，导致CPU的Benchmark并不能很好地评估DSP的优劣

## DSP Benchmark的特点

> 一开始DSP Benchmark主要有设备厂商如TI、摩托罗拉等公司给出；
> 后来有了一些独立的DSP Benchmark如BDTIMark, EDN Benchmarks, DSPStone.

### DSP Benchmark 分类

DSP Benchmark可以分为如下三类：

1. Processor:
   - Benchmark必须由汇编编写，从而避免编译器的影响
2. Compiler:
   - Benchmark由高级语言编写，由编译器进行编译
   - 同时需要手写的汇编语言版本的Benchmark
   - 运行两个程序，统计**cycle**跟**memory usage**，比较二者的差异从而评估编译器的性能
3. Platform(Processor & Compiler)
   - Benchmark由高级语言编写
   - 通过运行的性能来整体评估处理器跟编译器的性能

### Benchmark评估途径

1. 单看指标(Metrics):
   - 单看DSP Benchmark跑分，如MIPS(Million Instruction per Seconds)
   - 没有意义：因为不同的DSP架构不同，其每一条指令做的事儿不同，因此指令数多表不代表执行的计算多
2. 完整的DSP应用(Complete DSP Application):
   - 执行真正的DSP应用，例如调制解调、编码译码等操作
   - 这些程序通常是上千行的c代码
   - 评价的是<u>Platform</u>性能
3. DSP算术核心(DSP algorithm kernel):
   - 专门评估DSP算术核心的性能，如FIR, IIR, FFT, Convolution
   - 这些计算在DSP处理中占用了大量的执行时间
   - 从DSP应用程序里提取出专门的计算部分

### Benchmark评估的指标

1. 周期数(Cycle Count)
2. 内存使用(Program Memory Usage & Data Memory Usage)
3. 程序执行时间(Execution Time)
4. 功耗(Power Consumption)

## DSP常见的Benchmark

> 由于DSP系统的多样性，设计一款适合所有DSP系统的Benchmark不容易

### Dhrystone Benchmark

1. [Dhrystone官网](https://github.com/search?q=Dhrystone&type=repositories)
2. 并不主要是DSP的Benchmark，主要是CPU Benchmark
3. 有如下缺点:
   - Benchmark程序太小，导致有Cache的处理器评分会高很多
   - 测试程序权重差异太大，strcpy, strcmp占据了30%~40%的执行时间
   - 程序调用太浅，函数调用主要是3层

<!-- ### EDN's DSP Benchmark -->

### ※EEMBC Benchmark

1. [EEMBC官网](https://www.eembc.org/)
2. 由C编写、其测试用例包括：自动驾驶、物联网、机器学习、**数字通信**等行业
3. 主要测试的是DSP algorithm kernel的性能，从DSP应用里提取了计算密集的相关代码
4. 包含很多Benchmark以针对不用的应用场景：
   ![](https://s2.loli.net/2023/09/08/EPngJXj74zOiK6a.png)

### ※BDTI Benchmark

> BDTI DSP 内核基准测试是世界上使用最广泛的数字信号处理基准测试。几乎每个 DSP 处理器的主要供应商或买家都使用此基准测试套件。

1. [BDTI官网](https://www.bdti.com/services/bdti-dsp-kernel-benchmarks##:~:text=The%20BDTI%20DSP%20Kernel%20Benchmarks%20are%20a%20suite%20of%20twelve,in%20most%20signal%20processing%20applications)
2. 由汇编编写，测试Processor的性能，不评估 I/O、外设或外部存储器的影响
3. 包含12个 DSP 算法内核基准测试的套件，如FIR, IIR filters, LMS filter, convolutional encoder和FFT的算术性能
   ![](https://s2.loli.net/2023/09/08/LQaIDsocKSU7d3j.png)
4. Benchmark结构默认是所有测试项的平均分，但是用户可以根据应用的倾向为测试分配权重
5. Benchmark跑分受处理器数据格式影响，例如定点数的处理器跑分会高于浮点数处理器

### ※DSPStone Benchmark

1. [DSPStone官网](https://www.ice.rwth-aachen.de/research/tools-projects/closed-projects/dspstone)
2. 测试Platform的性能(Processor & Compiler):
   - 编译器性能评估：编译器生成代码的大小&代码执行的性能
   - 处理器性能评估：Benchmark代码执行的效率
3. 专门针对DSP的Benchmark

## 参考文献

1. [BDTI DSP Kernel Benchmarks](https://www.bdti.com/services/bdti-dsp-kernel-benchmarks)
2. [Genutis, M., E. Kazanavicius, and O. Olsen. "Benchmarking in DSP." Ultragarsas/Ultrasound 39.2 (2001): 13-17.](https://www.ultragarsas.ktu.lt/index.php/USnd/article/view/8050/4009)
3. [Dhrystone Benchmark](https://www.eembc.org/techlit/datasheets/dhrystone_wp.pdf)
4. [EEMBC Community](https://www.eembc.org/)
5. [Zivojnovic, Vojin. "DSPstone: A DSP-oriented benchmarking methodology." Proc. Signal Processing Applications & Technology, Dallas, TX, 1994 (1994): 715-720.](https://www.ice.rwth-aachen.de/fileadmin/Publications/Attachments/Zivojnovic94icspat.pdf)
