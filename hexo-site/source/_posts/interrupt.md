---
title: 中断的硬件实现
date: 2023-10-10 22:27:26
tags: RISC-V
---

中断的硬件逻辑

<!--more-->

# 中断的硬件实现(寄存器级描述)

硬件分为3个部分：

1. CSR寄存器部分（保证处理器核在硬件上支持中断）
2. CLINT（终断控制、终断优先级等部分）
3. PLIC（用于控制外部中断）

## 中断介绍

1. 中断源、中断请求
2. 中断服务程序(Interrupt Service Routine, ISR)
3. 保存现场、恢复现场
4. 中断优先级（每个中断源配备<u>级别寄存器</u>、<u>优先级寄存器</u>）、中断仲裁
   ![](https://s2.loli.net/2023/10/12/i6utj2dS3cnRV5p.png)
   TODO: 看6.2.9节关于优先级定义的部分

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

5. 根据RISC-V的架构定义，处理器当前的Machine Mode或者User
   Mode并没有反映在任何软件可见的寄存器中（<u>处理器内核会维护一个对软件不可见的硬件寄存器</u>），
   因此软件程序无法通过读取任何寄存器而查看当前自己所处的Machine

![](https://s2.loli.net/2023/10/12/5AcQGMhEDR8JTNi.png)

### 时钟中断

1. 触发条件：`mtime>=mtimecmp`
2. mtime每个cycle自增1，当满足触发条件的时候，由CLINT产生timer中断
3. 由`mie`寄存器的`MTIE`字段使能该中断、由`mip`寄存器的`MTIP`来指示timer中断是否在pending
4. timer 的寄存器在 timer 设备里，不在 CPU 中，是通过 MMIO 的方式映射到内存中的；都可以按照内存映射的方式被读写
5. 满足时钟中断触发条件之后，对应的处理函数会将`mtimecmp+=inerval`，这样触发条件又不满足了
   TODO: ask 我们系统是不是没有实现时钟中断？我们是不是不需要时钟中断

### 软件中断

1. 定义：软件触发的中断、主要指核间中断IPI(internal processor Interrupt)
2. 通过写入`mip`寄存器的`MSIP`字段来触发

### 外部中断

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
2. mtvec:
   - 可以配置向量模式跟非向量模式，向量模式下中断响应最快
   - 非向量模式下(参考[该文章](https://www.rvmcu.com/quickstart-show-id-1.html#38)5.13):
     - mtvt2[0]==0: 中断跟异常都通过mtvec指定地址
     - mtvt2[0]==1: 中断通过mtvt2指定地址
3. mepc
4. mcause：指令trap的原因；mcause[31]==1表示是外部中断、否则是异常；
   <!-- ![](https://img2023.cnblogs.com/blog/1653979/202307/1653979-20230712210012313-359133103.png) -->
   mcause代码参考[该文章](https://www.rvmcu.com/quickstart-show-id-1.html#38)的3.4.2节
   ![20231012172130.png](https://s2.loli.net/2023/10/12/1waFnRdjViUW7fx.png)  
   trap发生的时候, `mcause`会被硬件写入，记录trap发生的原因
5. mie: 针对各种类型的指令，指明当前处理器会处理哪些中断、忽视哪些中断
6. mip: 列出目前正准备处理的中断
7. mtval: 保存了陷入（trap）的附加信息，当触发硬件断点、地址未对齐、access fault、page fault 时，mtval 记录的是引发这些问题的虚拟地址；如果是由非法指令造成的异常，则将该指令的指令编码更新到mtval寄存器中
8. mscratch: 暂时存放一个字大小的数据
   > 将所有三个控制状态寄存器 虑，如果 `mstatus.MIE = 1，mie[7] = 1，且 mip[7] = 1`，则可以处理机器的时钟中断

# PLIC(Platform-Level Interrupt Controller)

# CLIC(Core-Local Interrupt Controller)

1. 作用：用于多个内部中断、外部中断进行仲裁；支持嵌套中断；向core发送中断信号
   ![](https://s2.loli.net/2023/10/12/EGjYsOaxdPM9iNqng)
2. 中断目标: 生成一根中短线发送给Core，这根线就称作为中断目标
   ![](https://s2.loli.net/2023/10/12/gBTxzArW12EqlGp.png)
3. 中断源:
   - RISC-V默认支持4096个中断源
   - 每个中断源有如下参数:
     - 编号(ID): 0~18被预留为内核使用，其余的中断ID从19开始
     - 使能位(IE)
     - Pending位(IP)
     - 级别跟优先级(Level and Priority)
     - 向量或非向量处理(Vector or Non-Vector Mode)
4. 阈值：仲裁出的中断源，其Level必须大于阈值，才会最终被发送给Core
5. 仲裁原理:
   - 中断源参与仲裁的条件: `enable & pending ==1`
   - 仲裁原理：先比较Level，再比较Priority，在比较ID（数字都是越大越好）

# 我们的实现

## CORE的硬件支持

![IMAGE-20231013212119766](HTTPS://S2.LOLI.NET/2023/10/13/O3TBTVYWXHVN1DY.PNG)

> PS: 目前CORE可以顺序的执行I-MEMORY里的指令，并且可以对BRANCH、JUMP指令正确地跳转到对应PC，
>
> 现在需要增加对中断的支持；中断=中断(INTERRUPT)+异常(EXCEPTION)

### CORE对中断进行处理，需要增加如下的功能:

1. 接受中断发生的信号
2. 中断发生时，跳转到对应的处理程序的能力
3. 辨别不同类型的中断的能力

> PS: 对中断处理的主要动作是**当中断发生的时候->停止当前的工作流->按照中断的类型完成对应的处理->恢复之前的工作流**。

### CORE需要提供的硬件支持

> 为了实现上述3种功能，CORE需要在原来五级流水线的基础上增加如下的硬件支持

#### 接受中断信号

1. CORE需要接受一个中断发生的信号，以通知CORE当前发生了中断

   > 具体指**ID STAGE**需要接受信号、知道中断发生了，因为ID STAGE负责PC的更新

![IMAGE-20231013220122658](HTTPS://S2.LOLI.NET/2023/10/13/WIVUFA6KOAXTEJ2.PNG)

2. RISC-V规定了3种类型的中断，分别是：外部中断、软件中断、定时器中断，其来源会在下文`MCAUSE`部分介绍

#### 🌟CSR寄存器及其操作

1. 记录中断的发生:

   ![IMAGE-20231013211942338](HTTPS://S2.LOLI.NET/2023/10/13/PMEJCZUNF93LO1C.PNG)

   > 中断使能位在`CSR.MIE`寄存器中配置

   - CSR.MIP寄存器用于记录各种PENDING的中断
     ![IMAGE-20231013131939115](HTTPS://S2.LOLI.NET/2023/10/13/HPOTSMUENJWJQBV.PNG)
   - PLIC检测到外部中断之后，会发送一个`NOTIFY`信号到CSR单元，表明外部中断发生; 导致`CSR.MIP[11]=1;`
   - TIMER触发时钟中断之后，也会发送一个`NOTIFY`信号到CSR单元，表明时钟中断发送; 导致`CSR.MIP[7]=1;`
   - 软件中断（通常用于向另一个核发送），此时可以通过MMIO的方式往另一个核的CSR单元写入; 导致`CSR.MIP[3]=1;`

2. 判断中断发生
   ![IMAGE-20231013212029071](HTTPS://S2.LOLI.NET/2023/10/13/5ITMZIA8ESZWRR1.PNG)

   > 如上所述：3种中断发生之后，都会通过硬件在1个CYCLE内记录到`CSR.MIP`寄存器中，现在可以对中断进行处理了

   - 中断判断在`TRAP_HANDLER`单用中完成（为了代码结构清晰)，它通过输入`CSR.MIP, CSR.MIE`信号，判断中断是否发生;
     若发生中断，则会将`TRAP`信号拉高，该信号会被ID STAGE使用, `TRAP=MIP[X] & MIE[X], X=3,7,11`
   - `TRAP`信号会发送给CORE跟CSR单元，完成相应的硬件操作以支撑中断

3. 记录中断的类型&更改处理器状态

   ![IMAGE-20231013213455624](HTTPS://S2.LOLI.NET/2023/10/13/WOXUGF3LM5KEWTY.PNG)

   - 在中断发生的时候，硬件会自动更新CSR.MCAUSE寄存器，保存中断的原因
     ![](HTTPS://IMG2023.CNBLOGS.COM/BLOG/1653979/202307/1653979-20230712210012313-359133103.PNG)
   - 例如“外部中断发生”之后，`CSR.MCAUSE`寄存器的`EXCEPTION CODE`字段会被写入`0X80000800`
   - 中断处理程序(INTERRUPT SERVICE ROUTINE, ISR)通过查询`CSR.MCAUSE`，就可以知道中断的原因，进而做想要的操作
     ![](HTTPS://S2.LOLI.NET/2023/10/13/UN9SPX3VNSYX5OC.PNG)
   - 中断判定之后，需要修改`CSR.MSTATUS`寄存器以更改处理器状态，
     硬件默认会将`CSR.MSTATUS.MPIE=CSR.MSTATUS.MIE, CSR.MSTATUS.MIE=0`，默认不支持中断嵌套
   - <U>中断嵌套</U>: 进入ISR后，可以通过CSR指令(如CSRRW)将`CSR.MSTATUS.MIE`置1从而再次打开中断，实现中断嵌套

4. 跳转到ISR执行

   > 中断处理核心的工作就是更改PC，从而跳转到ISR并且从ISR返回

   ![IMAGE-20231013214933645](HTTPS://S2.LOLI.NET/2023/10/13/SJGC6QD7HUSZ1BL.PNG)

   - `CSR.MTVEC`存放ISR的地址: 上面的`TRAP`信号被拉高之后，ID会将`PC_INSTR`更新为`MTVEC`的值，起到跳转到ISR的功能;
     `CSR.MTVEC`会在<U>系统初始化</U>的时候被CSR指令写入
   - 记录ISR返回的PC到`CSR.MEPC`中: `MEPC = INTERRUPT ? PC_NEXT : PC;`
   - 在ISR中，需要通过指令来保存上下文到D-MEMORY（栈区），栈指针有`CSR.MSCRATCH`寄存器给出
     ![](HTTPS://S2.LOLI.NET/2023/10/13/JQQOLPZ9WFN4GBU.PNG)

5. 从ISR返回

   > 中断处理结束之后，ID需要将PC更换为MEPC的值，从而继续之前的任务

   ![IMAGE-20231013222648570](HTTPS://S2.LOLI.NET/2023/10/13/CWPUMHTHDAOKYU7.PNG)

   - 从ISR返回的条件是执行到了`MRET`指令（在此之前，ISR已经通过指令完成了上下文的恢复才会调用`MRET`指令）
   - ID STAGE会将PC替换为`CSR.MEPC`的值，并且CSR相关的`STATUS`, `MIP`寄存器会被硬件恢复为中断之前的状态
   - PLIC同样需要接受MRET信号，从而判定当前中断已经处理完成、去仲裁新的外部中断

## 中断发生时，硬件自动完成的操作

> 有了上述硬件支持之后，中断发生之后，下述操作会有硬件自动完成：

- 异常指令的 PC 被保存在 MEPC 中，PC 被设置为 MTVEC
- 根据异常来源设置 MCAUSE
- 把控制状态寄存器 MSTATUS 中的 MIE 位置零以禁用中断，并把先前的 MIE 值保 留到 MPIE 中
- 发生异常之前的权限模式保留在 MSTATUS 的 MPP 域中，再把权限模式更改为 M(咱们只实现了M模式，故这一步可以省略)

# 参考文献

1. [RISC-V 手册 10.3](http://riscvbook.com/chinese/RISC-V-Reader-Chinese-v2p1.pdf)
2. [详解RISC v中断](https://www.cnblogs.com/harrypotterjackson/p/17548837.html)
3. [Nuclei_N级别指令架构手册](https://www.rvmcu.com/quickstart-show-id-1.html#38)
4. [RISC-V 中断子系统分析——CPU 中断处理](https://tinylab.org/riscv-irq-analysis-part3-interrupt-handling-cpu/)
5. [RISC-V 中断子系统分析——硬件及其初始化](https://tinylab.org/riscv-irq-analysis/)
