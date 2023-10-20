---
title: 付杰周报-20230923
date: 2023-03-08 14:45:34
tags: RISC-V
---

[TOC]

发现的问题：

1. CSR寄存器写入的cycle晚了1个cycle

   - [x] bug 已修复
   - bug 描述：

     ```asmble
        _start:
           nop
           nop
           nop
           la a5, _ISR
           csrw	mtvec, a5
           ecall
           nop
           nop
           nop
     ```

     `csrw mtvec, a5`将a5的值写入到`CSRs[8]`寄存器中，`ecall`指令执行的时候会触发软件中断，
     将pc的值替换成`mtvec`的值，但是`mtvec`得更新迟了1个cycle，导致pc没有更新为正确的`mtvec`的值
     ![](https://s2.loli.net/2023/10/18/FEwxjb9VWT8mdfk.png)

     ```verilog
      // file: CSR.v
      //mtvec
      always @(posedge clk)
      begin
          if(~resetn)
          begin
          CSRs[8] <= 32'h80000000;//initialized as zero, to be reset by booting software
          end
          else if(wen2&waddr2 == 12'h305)
          begin
          CSRs[8] <= wdata2;
          end
      end
     ```

   - bug 修复：将CSR写入逻辑提前1个cycle
     ```verilog
       // file: CSR.v
       //mtvec
       always @(posedge clk)
       begin
           if(~resetn)
           begin
           CSRs[8] <= 32'h80000000;//initialized as zero, to be reset by booting software
           end
           else if(wen1&waddr1 == 12'h305)
           // else if(wen2&waddr2 == 12'h305)
           begin
           CSRs[8] <= wdata1;
           end
       end
     ```
     ![](https://s2.loli.net/2023/10/18/i4O8qsXAT7JjYKt.png)

2. csr寄存器的写入，是否有bypass逻辑？

   ```asmble
      _start:
         nop
         nop
         nop
         la a5, _ISR
         csrw	mtvec, a5
         ecall
         nop
         nop
         nop
   ```

   上述代码，`csrw mtvec, a5`在ID Stage译码，3个cycle之后才会将a5的值写入到mtvec中，ecall指令触发软件中断，导致pc重定向
   的时候，需要将pc的值更新为mtvec的值

   - [ ] **需要讨论下相关的写入时序**
   - [ ] 需要讨论ecall指令触发`htrap_handler`的时机(ecall指令后面紧跟的指令是继续执行，还是直接跳转到mtvec处执行？) :

     - ecall在ID Stage译码完成之后，直接拉一个信号线告诉`htrap_handler`？
     - ecall在ID Stage译码完成之后，通过pipeline告诉`htrap_handler`？需要flush掉更多的指令（无用功）

     > ps: 中断导致的重定向，本来就会flush掉2条指令

3. trap发生的时候，mepc没有根据中断或异常做选择
   - [x] bug 已修复
   - bug 描述：
     ![](https://s2.loli.net/2023/10/18/sPFRDW3Iw1qHao5.png)
   - bug 修复：mepc需要区分外部中断、内部异常
     `mepc=interrupt ? pc_next : pc`
# 增加ecall测试用例

## 修改的部分

## 发现的问题

# 测试外部中断

# RISC-V 问题&解决方法

`hazard unit`计算`flush_d_i`的时候，没有考虑ecall指令，ecall指令在ID Stage发现之后，
其后续3条指令都是无效指令(因为ecall指令产生效果到`htrap_handler`产生trap信号，有3个周期)
![](https://s2.loli.net/2023/10/19/bT3RBCZKkFqW9AG.png)

- 目前的逻辑是：ID Stage译码到`ecall`指令之后，尝试修改`CSRs[8]`寄存器的值，然后`htrap_handler`
  会通过`CSRs[8]`寄存器的对应<u>software interrupt的位</u>来产生Trap信号发送到各个功能部件
  其核心逻辑在于**ID Stage已经检测到了ecall，但是还是需要htrap_handler来触发Trap信号**
