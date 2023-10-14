---
title: 付杰周报-20230923
date: 2023-03-08 14:45:34
tags: RISC-V
---

[TOC]

# 中断的硬件实现原理

## Core的硬件支持

![image-20231013212119766](https://s2.loli.net/2023/10/13/O3tbTVYWXhvn1dy.png)

> PS: 目前Core可以顺序的执行I-Memory里的指令，并且可以对Branch、Jump指令正确地跳转到对应PC，
>
> 现在需要增加对中断的支持；中断=中断(Interrupt)+异常(Exception)

### Core对中断进行处理，需要增加如下的功能:

1. 接受中断发生的信号
2. 中断发生时，跳转到对应的处理程序的能力
3. 辨别不同类型的中断的能力

> PS: 对中断处理的主要动作是**当中断发生的时候->停止当前的工作流->按照中断的类型完成对应的处理->恢复之前的工作流**。

### Core需要提供的硬件支持

> 为了实现上述3种功能，Core需要在原来五级流水线的基础上增加如下的硬件支持

#### 接受中断信号

1. Core需要接受一个中断发生的信号，以通知Core当前发生了中断

   > 具体指**ID Stage**需要接受信号、知道中断发生了，因为ID Stage负责PC的更新

![image-20231013220122658](https://s2.loli.net/2023/10/13/wivUfa6KOAXTej2.png)

2. RISC-V规定了3种类型的中断，分别是：外部中断、软件中断、定时器中断，其来源会在下文`mcause`部分介绍

#### 🌟CSR寄存器及其操作

1. 记录中断的发生:

   ![image-20231013211942338](https://s2.loli.net/2023/10/13/PmEjCzUnF93lo1c.png)

   > 中断使能位在`CSR.mie`寄存器中配置

   - CSR.mip寄存器用于记录各种pending的中断
     ![image-20231013131939115](https://s2.loli.net/2023/10/13/HPoTsMuENjwJQbV.png)
   - PLIC检测到外部中断之后，会发送一个`notify`信号到CSR单元，表明外部中断发生; 导致`CSR.mip[11]=1;`
   - Timer触发时钟中断之后，也会发送一个`notify`信号到CSR单元，表明时钟中断发送; 导致`CSR.mip[7]=1;`
   - 软件中断（通常用于向另一个核发送），此时可以通过MMIO的方式往另一个核的CSR单元写入; 导致`CSR.mip[3]=1;`

2. 判断中断发生
   ![image-20231013212029071](https://s2.loli.net/2023/10/13/5iTmZIa8ESzwrR1.png)

   > 如上所述：3种中断发生之后，都会通过硬件在1个cycle内记录到`CSR.mip`寄存器中，现在可以对中断进行处理了

   - 中断判断在`trap_handler`单用中完成（为了代码结构清晰)，它通过输入`CSR.mip, CSR.mie`信号，判断中断是否发生;
     若发生中断，则会将`Trap`信号拉高，该信号会被ID Stage使用, `Trap=mip[x] & mie[x], x=3,7,11`
   - `Trap`信号会发送给Core跟CSR单元，完成相应的硬件操作以支撑中断

3. 记录中断的类型&更改处理器状态

   ![image-20231013213455624](https://s2.loli.net/2023/10/13/WOxugf3lM5KEwty.png)

   - 在中断发生的时候，硬件会自动更新CSR.mcause寄存器，保存中断的原因
     ![](https://img2023.cnblogs.com/blog/1653979/202307/1653979-20230712210012313-359133103.png)
   - 例如“外部中断发生”之后，`CSR.mcause`寄存器的`Exception Code`字段会被写入`0x80000800`
   - 中断处理程序(Interrupt Service Routine, ISR)通过查询`CSR.mcause`，就可以知道中断的原因，进而做想要的操作
     ![](https://s2.loli.net/2023/10/13/uN9Spx3VnsyX5Oc.png)
   - 中断判定之后，需要修改`CSR.mstatus`寄存器以更改处理器状态，
     硬件默认会将`CSR.mstatus.mpie=CSR.mstatus.mie, CSR.mstatus.mie=0`，默认不支持中断嵌套
   - <u>中断嵌套</u>: 进入ISR后，可以通过CSR指令(如CSRRW)将`CSR.mstatus.mie`置1从而再次打开中断，实现中断嵌套

4. 跳转到ISR执行

   > 中断处理核心的工作就是更改PC，从而跳转到ISR并且从ISR返回

   ![image-20231013214933645](https://s2.loli.net/2023/10/13/SJgC6qd7husZ1BL.png)

   - `CSR.mtvec`存放ISR的地址: 上面的`Trap`信号被拉高之后，ID会将`pc_instr`更新为`mtvec`的值，起到跳转到ISR的功能;
     `CSR.mtvec`会在<u>系统初始化</u>的时候被CSR指令写入
   - 记录ISR返回的pc到`CSR.mepc`中: `mepc = interrupt ? pc_next : pc;`
   - 在ISR中，需要通过指令来保存上下文到D-Memory（栈区），栈指针有`CSR.mscratch`寄存器给出
     ![](https://s2.loli.net/2023/10/13/JQqOlPz9WfN4GBU.png)

5. 从ISR返回

   > 中断处理结束之后，ID需要将pc更换为mepc的值，从而继续之前的任务

   ![image-20231013222648570](https://s2.loli.net/2023/10/13/cwpuMHThDAoKYU7.png)

   - 从ISR返回的条件是执行到了`mret`指令（在此之前，ISR已经通过指令完成了上下文的恢复才会调用`mret`指令）
   - ID Stage会将pc替换为`CSR.mepc`的值，并且CSR相关的`status`, `mip`寄存器会被硬件恢复为中断之前的状态
   - PLIC同样需要接受mret信号，从而判定当前中断已经处理完成、去仲裁新的外部中断

## 中断发生时，硬件自动完成的操作

> 有了上述硬件支持之后，中断发生之后，下述操作会有硬件自动完成：

- 异常指令的 PC 被保存在 mepc 中，PC 被设置为 mtvec
- 根据异常来源设置 mcause
- 把控制状态寄存器 mstatus 中的 MIE 位置零以禁用中断，并把先前的 MIE 值保 留到 MPIE 中
- 发生异常之前的权限模式保留在 mstatus 的 MPP 域中，再把权限模式更改为 M(咱们只实现了M模式，故这一步可以省略)

# ecall指令测试结果

1. 对ecall指令进行译码，产生ecall_inst信号传送给CSR，令`CSR.mip=1`；记录软件中断产

   ```verilog
    // trap_handler.v
    always @(posedge clk ) begin
        if(~resetn) begin
            soft_pending <= 1'b0;
        end else begin
            soft_pending <= inst_ecall;
        end
    end

    // file: CSR.v
    always @(posedge clk)
    begin
        if(~resetn)
        begin
            CSRs[14] <= 32'b0;
        end
        else
        begin
            // update CSR.mip register
            CSRs[14][3]<= soft_pending;
            CSRs[14][7]<= time_pending;
            CSRs[14][11]<= test_ext_pending;
        end

    end
   ```

2. 测试代码
   ![](https://s2.loli.net/2023/10/14/zjdlVZNM7KQrUF3.png)
3. 测试通过
   ![](https://s2.loli.net/2023/10/14/Bo1tWMh6gpLNidb.png)
