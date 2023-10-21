---
title: 付杰周报-20230923
date: 2023-03-08 14:45:34
tags: RISC-V
---

[TOC]

# 测试外部中断

1. 在spike中关闭其中断(编译spike的已经完成)
2. 在top里将PLIC的外部中断信号拉一根信号`ext_interrup`出去，在testbench里需要使用该信号
   ```cpp
    static void execute(uint64_t n) {
      for (; n > 0; n--) {
        g_nr_guest_inst++;
        exec_once(); // dut run 1 cycle
        cpu.pc = top->pc; // pc存入cpu结构体
        dump_gpr();       // 寄存器值存入cpu结构体
        if (top->commit_en) {
          difftest_step(top->pc, top->ext_interrupt); // spike run 1 cycle
        }
        if (npc_state.state != NPC_RUNNING)
          break;
      }
    }
   ```
3. 修改Difftest框架，传入`ext_interupt`信号，当该信号为高的时候，让Spike也触发外部中断
   ```cpp
        void difftest_step(uint64_t pc, int ext_interrupt) {
          CPU_state ref_r;
          ref_difftest_exec(1);
          if(ext_interrupt){ // if external interrupt happen, make Spike interrupt happen
                difftest_interrupt(pc);
            }
          ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT); // 从ref中拷贝寄存器状态
          checkregs(&ref_r, pc);
        }
   ```

![](https://s2.loli.net/2023/10/21/rYo47BPARDbwOeQ.png)

# 发现的问题

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

2. trap发生的时候，mepc没有根据中断或异常做选择

   - [x] bug 已修复
   - bug 描述：当中断发生的时候，mepc应该写入next_pc的值；当异常发生的时候，mepc应当写入当前指令的pc值，目前版本mepc没有做选择，都是写入的当前pc的值
     ![](https://s2.loli.net/2023/10/18/sPFRDW3Iw1qHao5.png)
   - bug 修复：mepc需要区分外部中断、内部异常
     `mepc=interrupt ? pc_next : pc`

3. trap发生的时候，hazard unit没有产生相应的flush信号，flush后续的指令

   - [x] bug 已修复
   - bug 描述：外部中断产生到Trap信号拉高再到从中断处理程序取出第一条指令，一共有3条
     无用的信号，需要被flush掉，但是hazard unit没有将对应flush信号拉高
     ![](https://s2.loli.net/2023/10/19/bT3RBCZKkFqW9AG.png)
   - bug 修复：hazard需要考虑外部中断跟软件中断的情况，然后拉高相应的flush信号

# RISC-V 问题思考&解决方法

1.  目前中断发现到Trap信号拉高，一共有2个cycle，感觉可以优化掉1个cycle
    ![](https://s2.loli.net/2023/10/20/C2QsfOlAbaj3W8n.png)

    - 目前的逻辑是：ID Stage译码到`ecall`指令、或者是PLIC发来外部中断信号之后，会修改`CSR.mip`寄存器的值，将对应的pending位拉高

      ```verilog
      // write CSR.mip
      always @(posedge clk)
      begin
          if(~resetn)
          begin
              CSRs[14] <= 32'b0;
          end
          else
          begin
              CSRs[14][3]<= soft_pending;
              CSRs[14][7]<= time_pending;
              CSRs[14][11]<= test_ext_pending;
          end
      end
      ```

      然后`htrap_handler`会通过`CSR.mip`寄存器的对应<u>中断位</u>来产生Trap信号、发送到各个功能部件

      ```verilog
          else if(mstatus[3]) // 全局中断使能
          begin
              ex_happen<=1'b0;
              if(mip[11]&mie[11]) // 外部中断发生&外部中断使能
              begin
                  cause<={1'b1,19'b0,1'b1,11'b0};
                  trap_flush<=1'b1;
                  intr_happen<=1'b1; // 进行中断处理信号拉高
                  intr_triggered<=1'b1;
              end
      ```

      > 其核心逻辑在于**检测到了中断->修改`CSR.mip`寄存器->htrap_handler触发Trap信号**

    - <u>解决办法</u>：`htrap_handler`可以不通过检测CSRs寄存器的值再判断软件中断发生，直接从ID Stage将
      `ecall`信号传给`htrap_handler`(或者从PLIC将`external_interrupt`信号传给`htrap_handler`)，这样`Trap`信号的拉高可以提前1个cycle

2. ID Stage有很多的重定向发生，例如分支预测、分支预测错误、中断异常等:

   - 重定向发生的时候，ID Stage产生的重定向pc需要2个cycle才可以取到对应的指令进行译码
   - 重定向的时候，FIFO里的指令都需要被flush掉，浪费了一些有用的指令，例如ecall后面的指令在FIFO里，但是ecall执行的时候，会flush掉FIFO;
     mret的时候，有需要从I-Memory里重新取出指令

     ```assembly
       _start:
          ecall
          li x1, 1
          li x2, 2
          li x3, 3
          li x4, 4
          li x5, 5
     
       _ISR:
          li x1, 11
          li x2, 12
          li x3, 13
          li x4, 14
          li x5, 15
          mret
     ```

     ![](https://s2.loli.net/2023/10/21/HBfNqmeJKTRa2Ud.png)
     如上面的指令流，ecall导致跳转到中断处理程序，但是跳转的时候并不是立刻能够取到`li x1, 11`指令，而是会多取3条指令，这3条指令都会被flush掉

   - <u>解决办法</u>：改善flush的逻辑，尽可能保存取出来的指令，而不是直接flush掉，这样函数返回的时候，可以快速有指令可以译码、还可以减少访问I-Memory的次数
     _例如：在进行中断处理的时候，将预取的指令保存在另一组寄存器里（pc 也需要保存），mret返回的时候，则用这组寄存器的值替换FIFO里的指令，从而避免指令的反复读取并且可以在返回的时候更快得到指令_
     ![](https://s2.loli.net/2023/10/21/kyczjql149AvWZV.png)
     
     > PS：静态分支预测器判断跳转导致flush的时候，也可以采用该优化方法

3.  复杂度上升之后的验证问题
    - 简单的功能模块，设计人员在设计完成之后，可以通过编写testbench来进行测试
    - 复杂的硬件，其测试向量(testcase)构建也更加复杂，需要精心设计以满足测试的全面
    - 复杂的模块很难通过人为设计testbench来验证功能的正确性，有如下一些原因:
      - 本身复杂：处理器核本身就比某个功能模块复杂
      - 交互复杂：各个模块、pipeline stage连线到一起之后，彼此之间会有一些交互，会互相影响，例如
        ID译码到ecall指令的时候，会修改CSR寄存器，CSR寄存器修改导致htrap_handler触发中断，中断又导致ID Stage产生重定向pc
      - Difftest框架失效（实现Difftest很困难）：在只验证处理器核的时候，由现成的开源处理器核如spike, nemu等可以作为Difftest的golden model，
        但是当引入外部中断的时候，没有相应的PLIC、CLINT单元可以作为Difftest的golden model，只能够通过比较处理器核的CSR寄存器来大概判断中断是否正确；或者是自己写相应的golden model
4.  TODO: 能否解决LW Stall，从而避免一个cycle的硬stall？
5.  TODO: 取指部分考虑到Cache时有什么设计？不要限制在ITCM的框架里
6.  TODO: 低功耗方面有什么设计？
