---
title: 付杰周报-20230815
date: 2023-03-08 14:45:34
tags: RISC-V
---

[TOC]

# 语法测试

## Spyglass检查语法错误

1. Top文件里，变量先使用后定义导致的错误
   ![](https://s2.loli.net/2023/08/21/4yrnpiKZPGIfAov.png)
2. Difftest函数导致的报错
   ![](https://s2.loli.net/2023/08/21/hx7tBJq1vgPDcHu.png)
3. 最终的测试报告
   ![](https://s2.loli.net/2023/08/21/XouUBkwxZa1f3MV.png)

> 项目地址：`/home/fujie/Developer/verify`

## Verilator检查语法错误

1. 发现的语法错误

   ```bash
        verilator --lint-only -Wall --top-module top top.
   ```

   ![](https://s2.loli.net/2023/08/21/bnEXsfLKIQ3taZz.png)

2. 修复完top的**变量名重定义**之后，再次检测语法错误，报错的情况如下：

   - 文件名跟模块名不一致：1个，已解决
   - pin没有连接：1个，已解决
   - 信号没有驱动：1个，已解决
   - 信号未被使用、信号某些比特未被使用：23个

     | 信号未使用字段      | 所属文件                  | 已解决 | 解决方法               |
     | ------------------- | ------------------------- | ------ | ---------------------- |
     | instr               | top                       | ✅     | difftest相关信号、忽略 |
     | instrIllegal_e_o    | pipelineID                | ✅     | 预留给CSR Unit、忽略   |
     | instr_i[6:0]        | extendingUnit             | ✅     | 只用得到部分bits，忽略 |
     | resetn              | memory_block              | ✅     | 删除该无用信号         |
     | sram_addr           | pipelineIF_withFIFO       | ✅     | verilator错误，忽略    |
     | ceb                 | pipelineIF_withFIFO       | ✅     | verilator错误，忽略    |
     | web                 | pipelineIF_withFIFO       | ✅     | verilator错误，忽略    |
     | flush_delay         | pipelineIF_withFIFO       | ✅     | 删除该无用信号         |
     | alu_calculation_e_i | pipelineMEM_withloadstore | ✅     | D-memory只有1k，忽略   |
     | clk                 | pipelineWB                | ✅     | 删除该无用信号         |
     | resetn              | pipelineWB                | ✅     | 删除该无用信号         |
     | fin_d_o             | hazard                    | ✅     | 删除该无用信号         |
     | ld_dst2             | hazard                    | ✅     | 删除该无用信号         |
     | jd2                 | hazard                    | ✅     | 删除该无用信号         |
     | jd_b3               | hazard                    | ✅     | 删除该无用信号         |
     | bptrt               | hazard                    | ✅     | 删除该无用信号         |
     | bptnt1              | hazard                    | ✅     | 删除该无用信号         |
     | bnt2                | hazard                    | ✅     | 删除该无用信号         |
     | resetn              | alu                       | ✅     | 删除该无用信号         |
     | e_last              | long_div                  | ✅     | 删除该无用信号         |
     | sub3_pc[34]         | long_div                  | ✅     | 保留进位位宽，暂未删除 |
     | rem[34:33]          | long_div                  | ✅     | 保留进位位宽，暂未删除 |
     | adder8[16]          | multi16                   | ✅     | 保留进位位宽，暂未删除 |

   ```bash
    # top name not match
    %Warning-DECLFILENAME: CSA32.v:5:8: Filename 'CSA32' does not match MODULE name: 'CSA35'
        5 | module CSA35(ain,bin,cin,sout,cout);
          |        ^~~~~
                           decoder.v:307:1: ... note: In file included from decoder.v
                           pipelineIF_withFIFO.v:4:1: ... note: In file included from pipelineIF_withFIFO.v
                           top.v:12:1: ... note: In file included from top.v
                           ... For warning description see https://verilator.org/warn/DECLFILENAME?v=5.014
                           ... Use "/* verilator lint_off DECLFILENAME */" and lint_on around source to disable this message.

    # pin empty
    %Warning-PINCONNECTEMPTY: top.v:358:10: Cell pin connected by name with empty reference: 'mw_st'
      358 |         .mw_st                  (),
          |          ^~~~~

    # signals not driven
    %Warning-UNDRIVEN: hazard.v:26:26: Signal is not driven: 'mw_st'
                                     : ... In instance top.hu
       26 | output fd_st,de_st,em_st,mw_st;
          |                          ^~~~~
                       pipelineWB.v:40:1: ... note: In file included from pipelineWB.v

    # signals not used
    %Warning-UNUSEDSIGNAL: top.v:28:24: Bits of signal are not used: 'instr'[63:32]
                                      : ... In instance top
       28 |     input  wire [63:0] instr,
          |                        ^~~~~
    %Warning-UNUSEDSIGNAL: top.v:87:13: Signal is not used: 'fin_d_o'
                                      : ... In instance top
       87 |     wire    fin_d_o;
          |             ^~~~~~~
    %Warning-UNUSEDSIGNAL: top.v:99:11: Signal is not used: 'instrIllegal_e_o'
                                      : ... In instance top
       99 |     wire  instrIllegal_e_o;
          |           ^~~~~~~~~~~~~~~~

   ```

# MCU跑分

## 目前MCU的测试框架

> 目前MCU测试主要使用到了riscvtests跟difftest

1. riscvtests是由Berkeley设计的测试汇编程序，其覆盖了每种指令需要考虑的情况
2. difftest是YSYX提供的测试框架，其主要引入了如下三个部分:
   - golden model：符合riscv手册规范的参考模型
   - difftest框架：MCU每次执行一条指令，若该指令有效，都会让golden model指令相同的指令；然后比较二者的pc跟register file

![](https://s2.loli.net/2023/08/25/EKlSq2HC36XPjOf.png)

> 总结：目前MCU只支持**单纯的计算任务**

## YSYX的测试框架

> 在现有测试框架的基础上，在MCU的testbench里增加了相应的IO输出函数，但是仍然无法实现打印到终端的功能，其原因在于：编译microbench得到的bin文件，其不同于汇编文件编写的程序（只包含指令），还包含一些初始化的全局部变量、堆栈的初始化，因此需要**<u>搭建c环境</u>**，才能够编译c代码运行在MCU上

不同于riscvtest，microbench等测试程序是由c代码编写的，这些c代码需要调用一些库函数，例如`printf`。

假如像microbench这样的应用程序，需要在程序结束之后打印相关的结果到屏幕，则需要MCU提供相应的API支持，
这样应用程序才可以通过调用这些API的方式来实现打印的功能。

YSYX根据应用程序的需求，将其API进行分为如下五类，并且整合成一个库称为AM：

- TRM(Turing Machine) - 图灵机, 最简单的运行时环境, 为程序提供基本的计算能力
- IOE(I/O Extension) - 输入输出扩展, 为程序提供输出输入的能力
- CTE(Context Extension) - 上下文扩展, 为程序提供上下文管理的能力
- VME(Virtual Memory Extension) - 虚存扩展, 为程序提供虚存管理的能力
- MPE(Multi-Processor Extension) - 多处理器扩展, 为程序提供多处理器通信的能力

![](https://s2.loli.net/2023/08/25/9POAqdpwyQBukrx.png)

如果我们的处理器需要支持microbench打印跑分结果，则需要支持IOE扩展，主要分为以下的步骤：

1. 提供c程序运行所需要的API:
   - heap：指定堆栈的起始跟末尾、因为c程序里的函数调用、局部变量都是放在堆栈里的，跟指令是不同的
   - putch：输出一个字符
   - halt：结束程序的运行（汇编程序的结束是通过ebreak指令结束的，但是c程序需要该API才能够正常退出）
   - init：初始化MCU
2. 编译可以在MCU上运行的benchmark
   - riscv-gcc对benchmark.c文件进行编译得到目标文件
   - riscv-gcc对包含API的c文件进行编译得到目标文件
   - 编写链接脚本，该脚本需要指明每个节的末尾, 栈顶位置, 堆区的起始和末尾
   - 链接器将前面得到的目标文件链接成为可执行文件
3. MCU支持外设，以IO外设为例子
   - c程序本质上通过store指令完成写数据到屏幕的操作，因此MCU需要在MEM Stage根据地址，选择写入到Data Memory还是IO端口
   - MCU通过DPI-C函数，在MEM Stage声明一个DPI-C函数，实现写出到屏幕的功能

> 拟完成YSYX实验0~实验2内容

- 不了解其实现原理(如AM)，很难移植其相关代码到MCU，仅增加串口就花了很多时间，
  但是如果知道是AM是怎么组织的，则移植的时候速度会快很多。
- 完成实验2可以得到一个32bits的NEMU，后续可以作为reference model使用，
  Spike目前在测试riscvtest的时候还能够用，后续需要测试外部中断的时候，由于Spike
  内部细节不知道，因此在使用difftest测试中断的时候将会很麻烦（因为不知道Spike内部细节）
- 预计耗时2~3周，现在耗费时间掌握相关代码细节及原理，有助于后续MCU的集成测试
