---
title: 付杰周报-20231028
date: 2023-03-08 14:45:34
tags: RISC-V
---

[TOC]

# Dual FIFO 性能分析

![image-20231028074746545](https://s2.loli.net/2023/11/03/ONF41mJDGXEVcKC.png)

## C约定(C convention)

> RISC-V寄存器即函数调用约定，遵守该约定在能复用别人的代码

在RISC-V 32IMC指令集中，分支指令一共有如下两种:

1. JAL, JALR：主要在函数跳转的时候使用:

   - 在下面的代码中，main通过JAL跳转到add函数第一条指令
   - add通过ret指令返回到main函数

   > ret指令是伪指令，等价于`jalr x0, x1, 0`

2. B-Type: 主要用于控制程序流，做条件判断:
   - 在add内部的while循里，通过bgtz来判断循环的执行
   - 通过bgtz跳转到while循环内第一条指令
3. RISC-V寄存器约定, 假设函数A调用B:
   - ra, sp, a0-a17, t0-t6由A负责保存到栈上，B直接使用无需保存
   - s0-s11由B负责保存，返回到A的时候，需要将s0-s11恢复
     ![](https://s2.loli.net/2023/11/03/OBTGigK2x8JZQXE.png)
4. 函数调用vs控制程序流:
   - 函数调用需要遵守C约定，父函数跟子函数需要将需要保存的寄存器保存到栈上
   - 控制程序流只是pc的改变，不需要保存寄存器
   - 控制程序流不需要返回，函数调用需要返回

```c
int add(int n) {
  int sum = 0;
  while (n > 0) {
    sum += n;
    n--;
  }
  return sum;
}

int main() {

  int n = 3;
  int sum = add(n); // function call
  return 0;
}
```

![](https://s2.loli.net/2023/11/03/QEt2jCfgzkPR6u7.png)

## 函数调用

1. 函数A调用B的场景:

   - A减少SP，保存重要的通用寄存器，保存ra
   - 通过JAL, JALR跳转到B的第一条指令
   - 执行B的指令，调用ret返回到A
     ![image-20231103220929902](https://s2.loli.net/2023/11/03/AiBv6JzYhR5FcSd.png)

2. dual FIFO带来的优化:
   - 由于FIFO总共的容量为5，假设FIFO里预取的平均指令为2条
   - 在函数调用的时候，可以切换到空闲的FIFO，从而保存2条预取的指令
   - 函数返回的时候，可以直接从原来的FIFO里读取指令:
     - 避免4次ITCM访问(2条重复取指+2条Nop指令)
     - 避免2次Nop指令造成的流水线冲刷
     - 提前1个cycle完成函数调用返回

## 分支跳转

> dual FIFO会增加哪些硬件，量化描述

1. 分支指令的场景:
   - 译码期间分支预测跳转，切换到空闲的FIFO取指
   - ALU判断分支预测正确，冲刷掉之前的FIFO，在新的FIFO取指
   - ALU判断分支预测错误，返回到之前的FIFO顺序执行
     ![](https://s2.loli.net/2023/11/03/SUmgFJ9rPx68nVE.png)
2. dual FIFO带来的优化:
   - 预测正确的情况下，在时序取指上没有新能提升
   - 预测错误的情况下，可以直接返回之前的FIFO继续执行:
     - 避免4次ITCM访问(2条重复取指+2条Nop指令)
     - 避免2次Nop指令造成的流水线冲刷
     - 提前2个cycle取到正确的指令
   - 静态分支预测器有50%的预测准确率

## 异常&中断

1. 异常&中断的场景:
   - 外部中断出发之后，切换到空闲的FIFO执行<u>中断处理程序(ISR)</u>
   - ID Stage检测到ecall指令后，1个cycle后触发软件中断，此时切换到空闲的FIFO进行处理
   - ID Stage检测到mret指令之后，返回到之前的FIFO继续顺序执行
     ![](https://s2.loli.net/2023/11/03/bmAOuFYGtH6qNK7.png)
2. dual FIFO带来的优化:
   - 避免5次ITCM访问(3条重复取指+2条Nop指令)
   - 避免2次Nop指令造成的流水线冲刷
   - 提前2个cycle取到顺序执行的指令

## 数学量化

1. 假设程序里指令出现的概率如下所示:

   | 指令类型               | 出现概率  |
   | ---------------------- | --------- |
   | JAL, JALR              | x         |
   | B-Type                 | y         |
   | Interrupt, ECALL, MRET | z         |
   | alu                    | 1-(x+y+z) |

   假设分支预测器的预测跳转，但是实际不跳转的概率为`p`

2. 减少的访问ITCM比例: $\frac{4x+4py+5z}{1+4x+4py+5z}$
3. 减少NOP指令导致的冲刷的比例: $\frac{2x+2py+2z}{1+2x+2py+2z}$
4. 减少的返回的cycle比例: $\frac{1x+2py+2z}{1+1x+2py+2z}$

5. 硬件代价:
   - 第二个5\*16 FIFO(5\*16 bits寄存器，FIFO电路)
   - waiting_for寄存器，及其更新电路
   - free寄存器，及其更新电路
   - 在2个FIFO里选择数据的2选1 MUX

- [ ] TODO: 查阅文献，找到RISC-V中各种指令占比的统计
- [ ] TODO: 编译所有的benchmark, T502里面的代码，得到反汇编文件里的指令占比

## 总结

采用Dual FIFO可以通过增加硬件电路的代价，减少访问ITCM的次数, 加快函数调用、中断处理、分支跳转的返回，起到节约功耗跟周期数的作用。

# RISC-V Verification

1. Q: Core复杂度很高的时候，我们如何解决验证复杂性的问题呢？
   可以通过划分验证层级，每个层级负责不同的测试点来解决。如果是Core，一般可以分成3级，Block test模块测试，Subsystem test子系统测试，System test系统测试。比如，先在BT测CtrlBlock控制模块内是否正确，再测试Backend后端的模块间交互是否正确，再在Core层测试程序运行是否正确，层级不同验证方法可能也不同
2. Q: 需要验证的模块是有多个部分拼起来的，彼此之间有一些数据交互，导致测试的逻辑变复杂了，我们该如何保证我们的验证覆盖所有的情况呢？
   A: 一般要先看模块的外部接口，然后看模块内部状态，然后看在什么内部状态下会有什么输入会改变状态
3. Q: 针对复杂的设计，构造testcase的时候，是手动构造么？还是有一些专门构造testcase的方法？
   具体的testcase可以通过<u>sv的随机约束产生</u>，但是测试用例也要根据测试点构造
4. Q: 香山在测试外部中断、Cache等模块的时候，是如何跟Core结合起来测试呢？
   A: 一般先做Block test，然后就跑ST了，中断是属于ST的，DCache和ICache分别属于Frontend和MemBlock

# 综合结果

![image-20231103235032035](https://s2.loli.net/2023/11/03/HdFCS9NlWDgBR1J.png)
项目地址：`/home/fujie/cheq/syn/`

1. 综合的时候，不支持`===`操作

   ![image-20231103233218341](https://s2.loli.net/2023/11/03/8qRjh6wbNmOTd7P.png)

   ![](https://s2.loli.net/2023/11/01/jd1G5b9QyfJSKuz.png)

2. mcu面积

   - f=500MHz
     ![image-20231104090150472](https://s2.loli.net/2023/11/04/upIlB7Ax6REC9gD.png)
   - f=1000MHz
     ![](https://s2.loli.net/2023/11/01/vn7sCHbeyw8lKTa.png)

3. mcu功耗参考
   ![](https://s2.loli.net/2023/11/01/1TpoBeOgbcz3SY6.png)

4. mcu频率

   - 找不到对应的约束文件

   ![image-20231103234349537](https://s2.loli.net/2023/11/03/zyUR8xnTQEbjwN3.png)

   - 从别的项目里拷贝里一个过来

     ![image-20231103234502316](https://s2.loli.net/2023/11/03/kNTaIJqut4PFWxm.png)

   - T=100ns, f=1/T=10MHz的时候是符合时钟约束的

     ```bash
     check_timing
     report_clock
     report_clock -skew
     ```

     ![image-20231104081637376](https://s2.loli.net/2023/11/04/KdLScfJlByu4vO8.png)

   - T=10ns, f=1/T=100MHz的时候是符合时钟约束的
     ![image-20231104083713345](https://s2.loli.net/2023/11/04/QCIJYlHycnWeLEP.png)
   - T=2ns, f=1/T=500MHz的时候是符合时钟约束的
     ![image-20231104085750352](https://s2.loli.net/2023/11/04/dHZJmYsRco1O5Vw.png)
   - T=1ns, f=1/T=1000MHz的时候是**<u>不符合</u>**时钟约束的
     ![image-20231104102148420](https://s2.loli.net/2023/11/04/4J8CGea9FIuQBHl.png)

# 参考资料

1. [基本的时序路径约束](https://cloud.tencent.com/developer/article/1653346)
2. [🌟Tcl与Design Compiler （六）——基本的时序路径约束](https://www.cnblogs.com/IClearner/p/6624722.html)
3. [Understanding RISC-V Calling Convention](https://inst.eecs.berkeley.edu/~cs61c/resources/RISCV_Calling_Convention.pdf)
