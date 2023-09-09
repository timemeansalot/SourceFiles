---
title: 付杰周报-20230815
date: 2023-03-08 14:45:34
tags: RISC-V
---

[TOC]

# Difftest中断

## 协同仿真(cosim)的过程

cosim 是怎么工作的呢？模拟器是软件实现的，它原子地执行一条条指令，同时记录下当前的状态，例如寄存器的取值、内存的状态等等。如果可以让 CPU 和模拟器锁步运行，也就是 CPU 执行一条指令，模拟器执行一条指令，然后比对状态，一旦出现不一致，就直接报错。但实际上 CPU 可能会更加复杂，因为它指令的执行拆分成了很多部分，需要针对流水线进行一些修改，使得它可以生成一个匹配模拟器的原子的执行流。

整体的工作流程如下：

1. 选择一个模拟器，自己写或者使用一个现成的。考虑到模拟器实现的功能和 CPU
   不一定一致，有时候需要修改模拟器的源码，所以可以考虑使用一些现成的开源软件，如果是为了 cosim 设计的就更好了。
2. 找到模拟器的单步执行接口，并且让模拟器可以把内部状态暴露出来。这一步可能需要修改源代码。
3. 修改 RTL，把指令的提交信息、寄存器堆的内容通过一些方法传递出来。
4. 修改仿真顶层，每当指令提交的时候，单步执行模拟器，然后比对双方的状态。

## Spike模拟器修改

> spike 实现了比较完整的 RISC-V 指令集，并且以库的形式提供了它的 API，但还需要一些修改，让它更加适合协同仿真:

1. step函数修改

   - spike 提供了 step 函数，就是我们想要的单步执行
   - 但是，spike 的 step 在遇到异常或者中断的时候也会返回，但实际上在处理器一侧，通常异常是单独处理的
   - 修改 spike 的 step 函数，如果遇到<u>异常</u>了，继续执行，直到执行了一条指令为止

2. pc修改:

   - spike 没有记录最后一次执行的指令的 pc，只记录了下一个 PC
   - 在发生<u>异常</u>的时候，就不会记录异常处理的第一条指令的 PC

3. 外设:

   - 方法一：用 C 代码再写一个外设的模型，接到模拟器的虚拟总线上
   - 方法二：将处理器外设的读取发送给模拟器

4. **中断**：

   - 中断就会比较麻烦，因为中断的时机比较难保证同步
   - 把模拟器的中断处理关掉，当 CPU 发送 trap 的时候，让模拟器也发生一次 trap
   - MCU需要监控所有的中断，Difftest框架需要将中断发送给模拟器
   - 当多个中断同时发生时，Difftest框架需要根据优先级选择最高的中断发送给模拟器
   - Q: 目前我们的中断具体有哪些？软件、定时器、外部?
     ![](https://s2.loli.net/2023/09/08/wjJSCqhL9QkNPug.png)

## 处理器修改

> 需要修改处理器，让它可以汇报每个周期完成执行的指令情况，具体的格式因实现而异，最后都需要把这些信息暴露给仿真顶层，可能的方法有：

1. 通过<u>多级的 module output 一路传到顶层</u>，最终是顶层模块的输出信号。这种方法改动比较大，而且麻烦。
2. 通过 <u>DPI 函数</u>，每个周期调用一次，把信息通过 DPI 的参数传递给 C 函数。这种方法比较推荐。
3. 通过仿真器的功能，例如 verilator 可以通过添加注释的方法，把信号暴露出去。

## 执行cosim

> CPU 执行一条指令，就让模拟器也 step 一步，然后比较二者的状态

1. 比较寄存器堆跟CSR寄存器的方法:

   - 比较写入到寄存器堆的数据
   - 比较寄存器堆所有寄存器的值

2. 比较内存(data memory)，针对顺序处理器可以采用如下的方法比较：
   1. 把处理器读写的日志放到一个队列 deque 中
   2. 让模拟器也记录下内存的读写
   3. 从 deque 进行 pop 和比对

## 参考文献

1. [单核处理器的协同仿真](https://jia.je/hardware/2023/03/23/core-cosim/)
2. [SMP-Difftest 支持多处理器的差分测试方法](https://github.com/OpenXiangShan/XiangShan-doc/blob/main/slides/20210624-RVWC-SMP-Difftest%20%E6%94%AF%E6%8C%81%E5%A4%9A%E5%A4%84%E7%90%86%E5%99%A8%E7%9A%84%E5%B7%AE%E5%88%86%E6%B5%8B%E8%AF%95%E6%96%B9%E6%B3%95.pdf)
3. [Co-simulation System](https://ibex-core.readthedocs.io/en/latest/03_reference/cosim.html)
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

