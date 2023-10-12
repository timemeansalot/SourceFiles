---
title: 中断的硬件实现
date: 2023-10-10 22:27:26
tags: RISC-V
---

中断的硬件逻辑

<!--more-->

# 中断的硬件实现

## 基础介绍

> 外部信号进入芯片后，通过中断控制器中的“<u>使能+信号+优先级+仲裁</u>”等逻辑，最终输出到 MCU

1. 在riscv中一共定义了三种状态中断，对于hart层面，hart包含local中断源和global中断源。
   而local中断只有Timer和Software中断两种，而global中断则称为external interrupts。
2. 只有global中断源可以被PLIC(Platform-Level Interrupt Controller) core响应，通常为I/O device;
   一般来说，timer和software是通过CLINT(CORE LOCAL INTERRUPT)，而外部中断通过PLIC处理;
   PLIC的实现是独立于hart的IP设计

![](https://file.elecfans.com/web1/M00/EA/AA/o4YBAGB31wiAM9-JAANkBBZmtbA604.png)
![](https://file.elecfans.com/web1/M00/EA/AA/o4YBAGB31wmAJXihAAav1rCEB30049.png)

3. 由于PLIC的使用是针对外部中断的，所以可以单独设置每个中断。可以设置如下的值：

   - 中断的优先级priotity
   - 中断挂起位pending
   - 中断使能enables
   - 中断阈值priority Thresholds

4. 常见的同步错误(异常)有如下四种：

   - 访问错误：访问了不该访问的地址空间，例如尝试写入到ROM
   - 执行到了ecall, ebreak指令
   - 在ID发现指令非法
   - 地址不对齐: RISC-V其实没有强制支持非对齐访存，因此不支持非对齐访存的处理器，存在该异常

   Notes: 所有 RISC-V 系统的共同问题是**如何处理异常和屏蔽中断**

## 中断处理操作

### 硬件操作

1. 更新pc，改变指令流
   ```verilog
   mepc= mcause[31] ? pc_next : pc; // 0->中断,1->异常
   pc=mtvec[1:0] ? Base+4*Cause : Base;
   ```
2. 设置中断原因到mcause寄存器
3. 更改中断权限
   ```bash
      mPIE=mIE; # 存储trap发生之前的中断使能位
      mIE=0     # 关闭中断
   ```
4. ~~保存处理器特权级: 只有m特权级就不用管这个字段~~

### 软件操作(中断处理程序)

1. 保存32个通用寄存器到堆栈: mscratch寄存器通常被用作**指向附加临时内存空 间的指针**，通过该指针就可以知道<u>通用寄存器该被压栈的位置</u>

2. 执行中断处理程序
3. 从栈上恢复通用寄存器的值

![](https://s2.loli.net/2023/10/11/xJUHts7W16z8BoT.png)

## 附录：必须实现的8个ÇSR寄存器

1. mstatus：指令处理器核的状态信息
   ![](https://img2023.cnblogs.com/blog/1653979/202307/1653979-20230712210012932-1184025042.png)
   - MIE是对应特权级下全局中断使能位
   - xPIE, xPP, xIE举例：从s特权级产生中断进入到m特权级时
     ```bash
        mPIE=mIE; # 存储trap发生之前的中断使能位
        mPP=s     # trap发生之前，处理器所处的特权级
        mIE=0     # 关闭中断
     ```
2. mtvec
3. mepc
4. mcause：指令trap的原因；mcause[31]==1表示是外部中断、否则是异常
   ![](https://img2023.cnblogs.com/blog/1653979/202307/1653979-20230712210012313-359133103.png)
5. mie: 指令当前处理器会处理哪些中断、忽视哪些中断
6. mip: 列出目前正准备处理的中断
7. mtval: 保存了陷入（trap）的附加信息
8. mscratch: 暂时存放一个字大小的数据

> 将所有三个控制状态寄存器 虑，如果 `mstatus.MIE = 1，mie[7] = 1，且 mip[7] = 1`，则可以处理机器的时钟中断

# 参考文献

1. [RISC-V 手册 10.3](http://riscvbook.com/chinese/RISC-V-Reader-Chinese-v2p1.pdf)
2. [详解RISC v中断](https://www.cnblogs.com/harrypotterjackson/p/17548837.html)
3. [Nuclei_N级别指令架构手册](https://www.rvmcu.com/quickstart-show-id-1.html#38)
4. [RISC-V 中断子系统分析——CPU 中断处理](https://tinylab.org/riscv-irq-analysis-part3-interrupt-handling-cpu/)
5. [RISC-V 中断子系统分析——硬件及其初始化](https://tinylab.org/riscv-irq-analysis/)
