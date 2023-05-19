---
title: RISC-V测试
date: 2023-05-15 15:30:47
tags: RISC-V
---

RISC-V 处理器验证
<!--more-->

[TOC]
## 处理器核验证的方法

1. 验证目标：验证处理器微架构设计，是否符合 RISC-V 手册的规范，保证处理器的行为符合 RISC-V 定义
2. 验证方法（从简单到复杂）：Self Check, Signature Comparison, Trace Log Comparison, Step and Compare

### Self Check

1. 验证方法：测试激励内包含了测试的正确答案，如果 DUT(Device Under Test) 的运行结果匹配争取答案，则测试通过，否则不通过  
   典型的代表是：**[riscv-tests](https://github.com/riscv-software-src/riscv-tests)**
   , 编写定量指令码验证内核的功能，
   - 包括各类指令的逻辑功能
   - 数据冒险
   - 分支跳转
   - 流水线刷新(refresh)、暂停(stall)
   - CSR 指令
2. 优点：
   - 最简单实现：测试的 assmbly 文件编写简单
   - 运行方式最简单：只需要将 assmbly 文件编译得到机器码，加载到 testbench 中运行
   - 运行结果最简单：只有正确和错误两种结果
3. 缺点：
   - 涉及到的 DUT 内部变量、状态最少
   - 正确答案、错误过程：DUT 是错误的，但是得到了跟正确答案一样的结果
4. Self Check 举例:
   ![Self Check Example](/Users/fujie/Pictures/typora/image-20230518180223338.png)

### Signature Comparison

1. 验证方法：
   - Self Check 的改进
   - 可以在关键时刻记录内部变量的信息到 Signature 中，将该 Signature 与参考的比较来判断 DUT 的功能  
     典型的代表是：**[riscv-compliance](https://github.com/lowRISC/riscv-compliance/blob/master/doc/README.adoc)**
   - 可以完成基础的功能性测试
2. 优点：
   - 相比 Self Check 在验证的时候，可以暴露更多内部的信息
3. 缺点：
   - 暴露的 DUT 内部信息、状态也是有限的
4. Signature Comparison 举例:
   ![Signature Comparison Example](/Users/fujie/Pictures/typora/image-20230518180427488.png)

### Trace Log Comparison

1. 验证方法：
   - 与 reference-model 进行对比来验证 DUT 的功能
   - 将测试用例编译，作为输入同时给到 DUT 和 reference-model，
     运行的时候分别记录 DUT 和 reference-model 的内部信息到 trace 文件中
   - 仿真完成之后：将二者的 trace 文件进行对比，如果匹配则表示验证通过
2. 优点：
   - 验证的时候会记录大量的内部状态，如：具体指令、寄存器信息、处理器状态信息等
   - 由于跟 reference-model 做对比，因此每个测试向量的正确答案不用知道，并且可以使用 ISG(instruction Sequence Generator)
     来生成随机的测试向量
3. 缺点：
   - 对于异步事件，很难做到 DUT 和 reference-model 一致，如：中断、调试、流水线暂停等
   - 时间长：需要完成所有仿真之后，再对 trace 文件进行比较
   - 仿真的 trace 文件会很大
   - 跑飞(runaway execution)
4. Trace Log Comparison 举例:
   ![Trace Log Comparison](/Users/fujie/Pictures/typora/image-20230518191123232.png)

### Sync/Async Step and Compare

1. 验证方法：
   - **业界质量最高、最高效的**验证方法
   - 在 Trace Log Comparison 的基础上，将比较的过程放到了仿真里
   - 每一步都会将 DUT 跟 reference-model 进行比较，如果不匹配会直接报错
2. 优点：
   - 验证的时候会记录大量的内部状态，如：具体指令, GPR, CSR, 和其他内部信息等
   - 在仿真的时候每个 cycle 都可以比较二者的内部状态，不需要存储仿真的结果到文件
   - 当异步事件发生的时候，也可以对 DUT 跟 reference-model 进行比较
   - 当发现仿真结果匹配不上的时候，会立刻结束仿真, 能够快速的报告错误
3. 缺点：
   - 实现的复杂度很高，需要处理异步事件发生时 DUT 和 reference-model 之间的同步
4. Step and Compare 举例:
   ![Imperas Open Verification to RISC-V](https://s2.loli.net/2023/05/19/y6BxWXvJ7dhOkle.webp)

## RISC-V 处理器验证组建

![test bench components](https://s2.loli.net/2023/05/19/trjTgvokFKhSi8V.png)

### 测试用例(Test Case Suite)

#### riscv-tests

1. RISC-V 基金会提供了一组开源的测试实例 riscv-tests，用于测试 RISC-V 处理器的指令功能
2. riscv-tests 中的测试程序由汇编语言编写，可由用户自行选择测试覆盖的指令集
3. 测试原理：
   - 由处理器运行指令的测试用例，并将每一步运行结果与预期结果对比
   - 如果对比结果不同，则 TestBench 控制处理器跳转至异常地址，停止执行程序，并在终端打印 FAIL
   - 如果对比结果相同，则处理器继续执行下一条指令，直到所有指令执行结束，TestBench 在终端打印 PASS
4. 测试的基本框架：

   - 所有的测试激励都有一个共同的入口地址，在 riscv-tests 里是 0x800000000
   - 从 0x800000000 会跳到 reset_vector 地址，完成内部寄存器的初始化、处理器状态的初始化
   - 初始化完成之后，调用 mret，跳转到第一个 test case 地址开始测试

   ```assmbly
        rv32ui-p-add:     file format elf32-littleriscv

        Disassembly of section .text.init:

        80000000 <_start>:
        80000000:	0500006f          	j	80000050 <reset_vector>
        ...
        80000050 <reset_vector>:
        80000050:	00000093          	li	ra,0
        80000054:	00000113          	li	sp,0
        ...
        8000017c:	01428293          	add	t0,t0,20  8000018c <test_2>
        80000180:	34129073          	csrw	mepc,t0
        80000184:	f1402573          	csrr	a0,mhartid
        80000188:	30200073          	mret   跳到mepc地址，80000018C

        8000018c <test_2>:
        8000018c:	00200193          	li	gp,2
        80000190:	00000093          	li	ra,0
        80000194:	00000113          	li	sp,0
        80000198:	00208733          	add	a4,ra,sp
        8000019c:	00000393          	li	t2,0
        800001a0:	4c771663          	bne	a4,t2,8000066c <fail>
   ```

5. 例：riscv-tests 中对 `ADD` 指令测试三部分功能：

   - asm test source file:

     - 加法操作正确性
     - 源/目的寄存器测试
     - bypass

     ```asm
        file: rv32ui-p-add.S
       -------------------------------------------------------------
        Arithmetic tests
       -------------------------------------------------------------

       TEST_RR_OP( 2,  add, 0x00000000, 0x00000000, 0x00000000 );
       TEST_RR_OP( 3,  add, 0x00000002, 0x00000001, 0x00000001 );

       ....
       -------------------------------------------------------------
        Source/Destination tests
       -------------------------------------------------------------

       TEST_RR_SRC1_EQ_DEST( 17, add, 24, 13, 11 );
       TEST_RR_SRC2_EQ_DEST( 18, add, 25, 14, 11 );
       TEST_RR_SRC12_EQ_DEST( 19, add, 26, 13 );
       ....
       -------------------------------------------------------------
        Bypassing tests
       -------------------------------------------------------------

       TEST_RR_DEST_BYPASS( 20, 0, add, 24, 13, 11 );
       TEST_RR_DEST_BYPASS( 21, 1, add, 25, 14, 11 );
       TEST_RR_DEST_BYPASS( 22, 2, add, 26, 15, 11 );
       ...
       TEST_RR_ZERODEST( 38, add, 16, 30 );
     ```

     ```assembly
        file: test_macros.h
       define TEST_CASE( testnum, testreg, correctval, code... ) \
           test_ ## testnum: \
               li  TESTNUM, testnum; \
               code; \
               li  x7, MASK_XLEN(correctval); \
               bne testreg, x7, fail;

       define TEST_RR_OP( testnum, inst, result, val1, val2 ) \
           TEST_CASE( testnum, x14, result, \
             li  x1, MASK_XLEN(val1); \
             li  x2, MASK_XLEN(val2); \
             inst x14, x1, x2; \

       define RVTEST_FAIL                                                     \
            fence;                                                          \
            1:      beqz TESTNUM, 1b;                                               \
            sll TESTNUM, TESTNUM, 1;                                        \
            or TESTNUM, TESTNUM, 1;                                         \
            li a7, 93;                                                      \
            addi a0, TESTNUM, 0;                                            \
            ecall
     ```

   - compile the asm file and get dump file

     ```assembly
        file: rv32ui-p-add.dump
        init system like reset RF, set trap vectors
       ...
        test codes
       ## add test
       8000018c <test_2>:
       8000018c:	00200193          	li	gp,2
       80000190:	00000093          	li	ra,0
       80000194:	00000113          	li	sp,0
       80000198:	00208733          	add	a4,ra,sp
       8000019c:	00000393          	li	t2,0
       800001a0:	4c771663          	bne	a4,t2,8000066c <fail>
       ...
       ## source/destination test
       80000324 <test_17>:
       80000324:	01100193          	li	gp,17
       80000328:	00d00093          	li	ra,13
       8000032c:	00b00113          	li	sp,11
       80000330:	002080b3          	add	ra,ra,sp
       80000334:	01800393          	li	t2,24
       80000338:	32709a63          	bne	ra,t2,8000066c <fail>
       ...
       ## bypass test
       80000368 <test_20>:
       80000368:	01400193          	li	gp,20
       8000036c:	00000213          	li	tp,0
       80000370:	00d00093          	li	ra,13
       80000374:	00b00113          	li	sp,11
       80000378:	00208733          	add	a4,ra,sp
       8000037c:	00070313          	mv	t1,a4
       80000380:	00120213          	add	tp,tp,1  1 <_start-0x7fffffff>
       80000384:	00200293          	li	t0,2
       80000388:	fe5214e3          	bne	tp,t0,80000370 <test_20+0x8>
       8000038c:	01800393          	li	t2,24
       80000390:	2c731e63          	bne	t1,t2,8000066c <fail>

        test fail operations
       8000066c <fail>:
       8000066c:	0ff0000f          	fence
       80000670:	00018063          	beqz	gp,80000670 <fail+0x4>
       80000674:	00119193          	sll	gp,gp,0x1
       80000678:	0011e193          	or	gp,gp,1
       8000067c:	05d00893          	li	a7,93
       80000680:	00018513          	mv	a0,gp
       80000684:	00000073          	ecall
        all test pass operations
       80000688 <pass>:
       80000688:	0ff0000f          	fence
       8000068c:	00100193          	li	gp,1  all test fass, set x3 to 1
       80000690:	05d00893          	li	a7,93
       80000694:	00000513          	li	a0,0
       80000698:	00000073          	ecall
       8000069c:	c0001073          	unimp
     ```

   - test bench output
     如果测试不通过，会显示不通过的测试 case，`case=x3>>1`
     ```assembly
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        ~~~~~~~~~~~~~ Test Result Summary ~~~~~~~~~~~~~~~~~~~~~~
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        ~TESTCASE:/Users/fujie/Desktop/Developer/git_repos/hbird/e203_hbirdv2/vsim/run/../../riscv-tools/riscv-tests/isa/generated/rv32ui-p-add ~~~~~~~~~~~~~
        ~~~~~~~~~~~~~~Total cycle_count value:      23205 ~~~~~~~~~~~~~
        ~~~~~~~~~~The valid Instruction Count:      14117 ~~~~~~~~~~~~~
        ~~~~~The test ending reached at cycle:      23165 ~~~~~~~~~~~~~
        ~~~~~~~~~~~~~~~The final x3 Reg value:          7 ~~~~~~~~~~~~~
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        ~~~~~~~~~~~~~~~~ TEST_FAIL ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        ~~~~~~~~~~######    ##       #    #     ~~~~~~~~~~~~~~~~
        ~~~~~~~~~~        ##  #      #    #     ~~~~~~~~~~~~~~~~
        ~~~~~~~~~~#####   #    #     #    #     ~~~~~~~~~~~~~~~~
        ~~~~~~~~~~       #######     #    #     ~~~~~~~~~~~~~~~~
        ~~~~~~~~~~       ##    #     #    #     ~~~~~~~~~~~~~~~~
        ~~~~~~~~~~       ##    #     #    ######~~~~~~~~~~~~~~~~
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     ```

#### riscv-compliance

[riscv-compliance](https://github.com/lowRISC/riscv-compliance/blob/master/doc/README.adocintroduction)
的目标是检查正在开发的处理器是否符合开放的 RISC-V 标准。
通过了 riscv-compliance 的设计，可以被声明为<u>RISC-V compliant</u>
![riscv-compliance](https://s2.loli.net/2023/05/19/mpz6BZsoAC152VN.png)

1. 选定了测试集之后可以编译得到可执行文件
2. 在 DUT 中执行可执行文件，仿真的时候会把内部变量写到某个内存中，仿真结束之后，会把内存里的数据 dump 到文件，得到仿真的 signatures
3. 将 signatures 跟正确的 signatures 比较，如果通过了则代表 DUT 通过测试
4. 仿真结束可以得到 Coverage Report

#### riscv-arch-test

[riscv-arch-test](https://github.com/riscv-non-isa/riscv-arch-test)
是按照 RISC-V 指令集模块化分类了的一个测试集

1. 其测试集是由[Compatibility Test Generator from InCore Semiconductors](https://github.com/riscv/riscv-ctg)生成的
2. 参考的 signatures 是有 spike 仿真得到的

```assmbly
 ├── env                        contains the architectural test header files
 └── rv32i_m                    top level folder indicate rv32 tests for machine mode
     ├── C                      include tests and references for "C" extension
     │   └── src                assembly tests for "C" extension
     ├── F                      include tests and references for "rv32F" extension
     │   ├── references         static references signatures for "rv32F" extension
     │   └── src                assembly tests for "rv32F" extension
     ├── I                      include tests and references for "I" extension
     │   └── src                assembly tests for "I" extension
     ├── M                      include tests and references for "M" extension
     │   └── src                assembly tests for "M" extension
     ├── K_unratified           include tests and references for "K" extension
     │   └── src                assembly tests for "K" extension
     ├── P_unratified           include tests and references for "P" extension
     │   ├── references         static references signatures for "P" extension
     │   └── src                assembly tests for "P" extension
     ├── privilege              include tests and references for tests which require Privilege Spec
     │   └── src                assembly tests for tests which require Privilege Spec
     └── Zifencei               include tests and references for "Zifencei" extension
         └── src                assembly tests for "Zifencei" extension
 └── rv64i_m                    top level folder indicate rv64 tests for machine mode
     ├── C                      include tests and references for "C" extension
     │   └── src                assembly tests for "C" extension
     ├── I                      include tests and references for "I" extension
     │   └── src                assembly tests for "I" extension
     ├── M                      include tests and references for "M" extension
     │   └── src                assembly tests for "M" extension
     ├── K_unratified           include tests and references for "K" extension
     │   └── src                assembly tests for "K" extension
     ├── P_unratified           include tests and references for "P" extension
     │   ├── references         static references signatures for "P" extension
     │   └── src                assembly tests for "P" extension
     ├── privilege              include tests and references for tests which require Privilege Spec
     │   └── src                assembly tests for tests which require Privilege Spec
     └── Zifencei               include tests and references for "Zifencei" extension
         └── src                assembly tests for "Zifencei" extension
```

#### 🌟🌟🌟🌟imperas test suite

[imperas test suite ](https://github.com/riscv-ovpsim/imperas-riscv-tests)

1. 针对不同的指令模块提供了测试集，如：I,M,C,F,D,B,K,V,P
2. 自带模拟器: riscvOVPsim simulators
3. 能够生成 Coverage Report
4. 参考资料丰富，GitHub, YouTube 上资源较多

### 指令流生成器(Instruction Stream Generators)

1. Google [ riscv-dv ](https://github.com/chipsalliance/riscv-dv): 较为稳定
   - 是一个基于 SV/UVM 的开源指令生成器，用于 RISC-V 处理器验证
   - 支持的指令集: RV32IMAFDC，RV64IMAFDC
   - 可以模拟 illegal instruction
2. [OpenHW Group force-riscv](https://github.com/openhwgroup/force-riscv): 主要用于 RV64，RV32 支持才开始

### 功能覆盖(Functional Coverage)

> 在一定的测试用例上对 DUT 进行测试，并且测试通过，只能说明 DUT 在这些测试用例上是正确的，
> 并不能 100%说明 DUT 功能就是正确。
> 为了 100%说明 DUT 功能是正确的，需要保证测试 Coverage 通过

1. SystemVerilog covergroups and coverpoints
2. Imperas build-in instruction coverage

### 参考模型(reference model)

1. spike
2. qeum
3. riscvOVPsim

### 总结

1. 如果知识对 DUT 进行基本功能测试，可以选择某个 test suite 进行测试，如果通过了测试，可以在一定程度上保证 DUT 功能的正确性.

   > you can never have enough tests

2. 如果需要 100%保证 DUT 功能正确，需要
   - 采用 asycn step and compare
   - 保证 Coverage Report 中 100%覆盖了 check point

## SoC 后续测试

### 功能性验证

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

### 板级验证

> FPGA 完全由用户通过行配置和编写并且可以反复擦写，非常适合用于嵌入式 SoC 系统芯片的原型验证

1. 设计的全部 RTL 代码进行下板, 进行板级验证
2. 可以发现隐藏的时序问题
3. debug: 支持在 host 上对 MCU 进行远程调试

### 时序、面积、功耗

使用 DC(Design Compiler) 综合工具将处理器的设计代码进行综合，以验 证本文时序、面积、功耗的设计要求

1. 转换：将 RTL 转化成没有优化的门电路，对于 DC 综合工具来说，使用的是 gtech.db 库中的门级单元
2. 优化：对初始化电路分析，去掉冗余单元、对不满足限制条件的路径进行优化
3. 映射：将优化后的电路映射到制造商提供的工艺库上

通过 DC 工具综合后可以得到 MCU 在时序、面积、功耗的报告

## References

1. [RISC-V 及 RISC-V core compliance test 简析](https://zhuanlan.zhihu.com/p/232088281)
2. [RISC-V Compliance Tests](https://github.com/lowRISC/riscv-compliance/blob/master/doc/README.adocintroduction)
3. [Imperas Test Suit](https://github.com/riscv-ovpsim/imperas-riscv-tests)
4. [riscv-arch-test](https://github.com/riscv-non-isa/riscv-arch-test)

