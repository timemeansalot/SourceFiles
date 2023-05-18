---
title: RISC-V测试
date: 2023-05-15 15:30:47
tags: RISC-V
---

RISC-V 功能测试，保证 RISC-V 处理器功能正确性

> To ensure that the processor implementation is respecting the RISC-V specification,
> you must pass the [riscv-tests](https://github.com/riscv-software-src/riscv-tests) provided by the RISC-V organization.

<!--more-->

## 指令集验证

1. 编写定量指令码验证内核的功能，
   - 包括各类指令的逻辑功能
   - 数据冒险
   - 分支跳转
   - 流水线刷新(refresh)、暂停(stall)
   - CSR 指令
2. 手段有限，只能确保内核运行的主体功能，异常处理功能（例如各类指令跳转）极少能验证充分

### riscv-tests

1. RISC-V 基金会提供了一组开源的测试实例 riscv-tests，用于测试 RISC-V 处理器的指令功能
2. riscv-tests 中的测试程序由汇编语言编写，可由用户自行选择测试覆盖的指令集
3. 测试原理：
   - 由处理器运行指令的测试用例，并将每一步运行结果与预期结果对比
   - 如果对比结果不同，则 TestBench 控制处理器跳转至异常地址，停止执行程序，并在终端打印 FAIL
   - 如果对比结果相同，则处理器继续执行下一条指令，直到所有指令执行结束，TestBench 在终端打印 PASS
4. riscv-tests 中对 `ADD` 指令测试三部分功能：

   - 加法操作正确性
   - 源/目的寄存器测试
   - bypass

   ![](https://s2.loli.net/2023/05/17/bCqhWITsr9jfglt.png)

## 功能性验证

> 利用*功能性 C 代码*来测试具体的功能，如：内部看门狗复位请求、UART 收发
>
> 1. 利用编译器生成的指令码进行验证，非常符合实际的行为
> 2. 但验证手段复杂，不适合一开始系统不稳定时候的验证

1. 初始化文件：
   - 由汇编编写，系统上电复位之后执行的第一段程序
   - 堆栈初始化、中断向量标及中断函数定义等
   - 系统复位后进入 main 函数
2. 编写需要测试的 C 文件
3. 对 C 文件调用工具链进行编译、从可执行文件中得到机器码、在 testbench 中通过系统函数$readmenh$加载到 I-Memory
   <!-- ```makefile -->
   <!-- CROSS_COMPILE=riscv32-unknown-elf -->
   <!-- CC=$(CROSS_COMPILE)gcc  -->
   <!-- CFLAGS=-c -nostdlib -march=rv32imc -mabi=ilp32  -->
   <!-- OBJCOPY=$(CROSS_COMPILE)objcopy OBJCOPYBINFLAGS=-O binary -j .text  -->
   <!-- OBJCOPYHEXFLAGS=-I binary -O ihex  -->
   <!-- OBJDUMP=$(CROSS_COMPILE)objdump  -->
   <!-- OBJDUMPFLAGS=-D -b binary -mriscv  -->
   <!-- LD=$(CROSS_COMPILE)ld  -->
   <!-- LDFLAGS=-melf32lriscv  -->
   <!-- INIT_DIR=../../init/  -->
   <!-- CODE_DIR=../code/  -->
   <!-- INC_DIR=../../include/ -->
   <!-- all: init.o gpio.o main.o  -->
   <!--     $(LD) $(LDFLAGS) -o target.o init.o gpio.o main.o  -->
   <!--     $(OBJCOPY) $(OBJCOPYBINFLAGS) target.o target.bin  -->
   <!--     $(OBJCOPY) $(OBJCOPYHEXFLAGS) target.bin target.hex  -->
   <!--     $(OBJDUMP) $(OBJDUMPFLAGS) target.bin > target.asm  -->
   <!-- init.o: $(INIT_DIR)init.s  -->
   <!--     $(CC) $(CFLAGS) $(INIT_DIR)init.s -o init.o  -->
   <!-- gpio.o: $(INC_DIR)riscv_gpio.c  -->
   <!--     $(CC) $(CFLAGS) $(INC_DIR)riscv_gpio.c -o gpio.o  -->
   <!-- main.o: $(CODE_DIR)main.c  -->
   <!--     $(CC) $(CFLAGS) $(CODE_DIR)main.c -o main.o  -->
   <!-- clean: -->
   <!--     rm -rf *.o *.bin *.hex *.asm *.dat -->
   <!-- ``` -->

## 板级验证

> FPGA 完全由用户通过行配置和编写并且可以反复擦写，非常适合用于嵌入式 SoC 系统芯片的原型验证

1. 设计的全部 RTL 代码进行下板, 进行板级验证
2. 可以发现隐藏的时序问题

## 时序、面积、功耗

使用 DC(Design Compiler) 综合工具将处理器的设计代码进行综合，以验 证本文时序、面积、功耗的设计要求

1. 转换：将 RTL 转化成没有优化的门电路，对于 DC 综合工具来说，使用的是 gtech.db 库中的门级单元
2. 优化：对初始化电路分析，去掉冗余单元、对不满足限制条件的路径进行优化
3. 映射：将优化后的电路映射到制造商提供的工艺库上

通过 DC 工具综合后可以得到 MCU 在时序、面积、功耗的报告

### riscv-tests

### difftest

### benchmark

### debug

TODO
