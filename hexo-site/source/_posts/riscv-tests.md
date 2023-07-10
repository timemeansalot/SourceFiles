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

## riscv-tests 环境搭建

1. 验证目录

   ```bash
    src
    ├── rtl
    │   ├── top.v
    │   ├── ...
    │   ├── ...
    │   ├── top_tb.v
    └── verification
        ├── Makefile
        ├── asm
        └── rtl
   ```

   1. 目前所有的源文件都在项目的`src`文件下
   2. `src/rtl`存档 MCU 的 verilog 代码
   3. `src/verification`是使用 riscv-tests 对 rtl 代码进行验证的目录
      1. `asm`：存放所有的 riscv-tests 的汇编测试文件
      2. `rtl`：存放所有的带测试的 verilog 源文件
      3. `Makefile`：存放所有验证时需要的一些命令，如“编译 verilog”、“编译汇编文件”、“仿真”等

2. Makefile 内容

   ```Makefile
   .DEFAULT_GOAL := wave
   # compile asm source file to get test cases for MCU
   asmCode:
   	@(cd asm && ./clean.sh && ./regen.sh && cd ..)
   # copy source file before compile
   copy:
   	@(rm -rf rtl/*.v && cp ../rtl/*.v rtl)
   # simulate DUT, you'd better `make asmCode` first to generated machine code
   sim:
   	@(cd rtl && make sim)
   # show waveform
   wave:
   	@(cd rtl && make waveform)

   # regression test
   # TODO: implement in the future.
   # Because MCU can't pass even one test file in riscv-tests now!
   # So we don't need to test the whole riscv-tests now.
   clean:
   	@(cd asm && ./clean.sh && cd ../rtl/ && make clean)
   # declare phone target
   PHONY: clean wave sim copy asmCode
   ```

   1. asmCode: 会进入到 asm 文件夹，并且调用脚本`regen.sh`编译所有的 riscv-tests 文件，并且得到机器码;  
      testbench 会从得到的机器码文件中，加载指令到 I-Memory 中
   2. copy：用`src/rtl`下复制所有的`.v`文件替换`verification/rtl`目录下的所有`.v`文件
   3. sim：会进入`verification/rtl`目录下，并且使用 make sim 命令，
      该命令会编译 rtl 文件，再执行 rtl 仿真
   4. wave：使用 gtkWave 查看仿真生成的波形
   5. regression test: 使用所有的 riscv-tests 测试用例测试 MCU，
      如果都通过了则说明 MCU 通过了 riscv-tests 测试;  
      但是现在的 MCU 一个测试都无法通过，所以目前暂时不支持 regression test.

3. 仿真结果
   riscv-tests 汇编文件，默认测试通过的时候，x3 的值为 1，所以每一轮仿真结束之后，我们在 testbench 里检查
   x3 的值就可以判断测试是否通过

   ![sim fail](https://s2.loli.net/2023/05/25/TcrkZPS9DbLeV8h.png)

## 用 Verilog 编写的 RISC-V 处理器接入到 Difftest 框架

- [ ] 接入 Difftest 框架
  - [ ] Difftest 框架使用了 AXI 和 UART 模块，如何忽略到这些模块
  - [ ] 如何在 MCU_core 中例化 Difftest 模块，只关心通用寄存器的数值是否匹配
  - [ ] 如何比较 MCU_core 跟 NEMU 中的 PC？因为采用了指令预取技术，MCU_core 并没有使用传统意义的 PC
  - [ ] 如何解决 Difftest 要求的时序问题
  - [ ] 如何具体测试 load/store 指令
- [ ] 使用 Difftest 框架进行测试
  - [ ] 如何根据 riscv-tests 生成测试用力加载到 MCU_core 以及 golden-model，NEMU 采用的是 1-bank, MCU_core 采用的是 2bank I-Memory
  - [ ] 测试通过的 riscv-tests
  - [ ] 测试发现的 bug、修改的 bug

1. 项目的框架如下:

   ```bash
        DifftestFramework
        ├── bin
        ├── nemu
        └── NOOP
            ├── difftest
            └── CPU
               ├── Core.v
               ├── Decode.v
               ├── Execution.v
               ├── InstFetch.v
               ├── Instructions.v
               ├── Ram.v
               ├── RegFile.v
               └── SimTop.v
   ```

   - bin: 测试文件
   - nemu: 指令集模拟器，用于作为比较的 golden model
   - difftest: 香山团队提供的 difftest 框架
   - CPU: 存放 MCU_core 实现及 SimTop
     - Core.v: MCU_core 文件，该文件里例化了各个流水线部件、**difftest 里的组件**(将对应的信号传递给 difftest)
     - SimTop.v：difftest 框架默认的顶层文件，在这个文件里需要例化 MCU_core

2. 测试流程：
   - 在系统环境里指明`NEMU_HOME`跟`NOOP_HOME`，二者分别应该被设置为`NEMU`跟`NOOP`的绝对路径，如上表所示
   - 克隆 difftest 需要用到的子模块，difftest 是从 GitHub 上克隆的仓库，其本身包含了一些其他的仓库，具体如下所示：
     进入到 difftest 目录下，使用命令`git submodule update --init recursive`来克隆所有需要的子仓库
     ```bash
        [submodule "rocket-chip"]
            path = rocket-chip
            url = https://github.com/RISCVERS/rocket-chip.git
        [submodule "block-inclusivecache-sifive"]
            path = block-inclusivecache-sifive
            url = https://github.com/RISCVERS/block-inclusivecache-sifive.git
        [submodule "chiseltest"]
            path = chiseltest
            url = https://github.com/ucb-bar/chisel-testers2.git
        [submodule "api-config-chipsalliance"]
            path = api-config-chipsalliance
            url = https://github.com/chipsalliance/api-config-chipsalliance
        [submodule "berkeley-hardfloat"]
            path = berkeley-hardfloat
            url = https://github.com/RISCVERS/berkeley-hardfloat.git
        [submodule "timingScripts"]
            path = timingScripts
            url = https://github.com/RISCVERS/timingScripts.git
     ```
3. 在 SimTop.v 文件中，例化 MCU_core
4. 在 NOOP 目录下，使用指令`make -C difftest emu`来编译所有的 Verilog 跟 Scala 文件，得到可运行的仿真程序。
   该仿真程序就是**支持将 MCU 跟 NEMU 进行比较的程序**。

   > PS: 编译仿真程序至少需要 32G 的内存，否则会报错说内存不够; 在服务器上编译了 68 分钟.

5. 编译测试文件：使用 riscv-tools 编译测试文件，得到二进制程序
6. 用测试二进制程序作为输入，进行 difftest。仿真程序会在匹配失败的时候，报错并且给出报错的信息。

# Difftest 接入过程实操记录

> DIFFTEST 的比对对象是两个核，一个是用户设计的核，一个是参考核。 比对原理是设计核在每提交一条指令的同时使参考核执行相同的指令，之后比对所有的通用寄存器和 csr 寄存器的值，如果完全相同则认为设计核执行正确

## MCU 接入 Difftest 步骤

1. **<u>编译 NEMU 作为参考对象</u>**，即 Golden Model。NEMU 是一个功能完备的模拟器，支持 x86/mips32/riscv32/riscv64 等 ISA

   - 克隆 NEMU 的 GitHub 仓库到本地
   - 在编译 NEMU 之前需要指定想要模拟的 ISA（因为 NEMU 支持多种 ISA）：`make menuconfig`
     ![](https://s2.loli.net/2023/06/29/JiOsqDT7Gh8opdf.png)
   - 在 NEMU 目录下使用`make`命令进行编译，得到 nemu-interpreter-so 动态链接文件，
     该文件会在 Difftest 编译时被引用

2. 在 <u>**MCU Core 中例化 Difftest 模块**</u>

   1. 为 Difftest 测试创建如下的目录结构
      ```bash
          DifftestFramework
          ├── bin
          ├── nemu
          └── NOOP
              ├── difftest
              └── CPU
                 ├── Core.v
                 ├── Decode.v
                 ├── Execution.v
                 ├── InstFetch.v
                 ├── Instructions.v
                 ├── Ram.v
                 ├── RegFile.v
                 └── SimTop.v
      ```
      - bin: 测试文件
      - nemu: 指令集模拟器，用于作为比较的 golden model
      - difftest: 香山团队提供的 difftest 框架
      - CPU: 存放 MCU_core 实现及 SimTop
        - Core.v: MCU_core 文件，该文件里例化了各个流水线部件、**difftest 里的组件**(将对应的信号传递给 difftest)
        - SimTop.v：difftest 框架默认的顶层文件，在这个文件里需要例化 MCU_core
        -
   2. 在 MCU_core 里例化各级流水线模块以及 Difftest 模块

      > 数据流传递方向可简单地认为是 `MCU_core.v`->`difftest.v`->`interface.h`->`difftest.cpp`

      - difftest.v 中定义了所有 dpic 相关的 verilog module 信息，
        这些 module 中会调用 c 函数用来传输信号。这些 module 会被设计核实例化用来传输信号。
      - mycpu_top.v 中实例化了 difftest.v 中定义的 module。
      - interface.h 是 c 函数的实现，c 函数将设计核的信号赋值给 difftest 中的变量。

      <u>有两种方法可以将以 verilog 编写的 MCU_core 链接入 Difftest 框架</u>：

      1. 参考龙芯团队[chiplab 开源项目中接入 Difftest](https://chiplab.readthedocs.io/zh/latest/Simulation/difftest.html)
         的文档。
         - 龙芯团队采用的是 verilog 来编写其 SoC
         - 处理器支持的指令集其 longarch，因此他们重构了 NEMU 以支持 longarch ISA
         - 他们接入 difftest 时直接有现成的 difftest.v 文件可以例化
         - 其给出的 Difftest Demo 可以在服务器上克隆下来并且跑通
      2. 参考一生一芯团队给出的 Difftest 相关教程、NEMU 相关教程
         - YSYX 团队最先提出在处理器设计中引入 Difftest 框架
         - YXYS 团队给出了 NEMU、以及 Difftest 的[源码解析](https://ysyx.oscc.cc/docs/ics-pa/0.6.html#git-usage)
         - 目前 YSYX 团队文档多以 Chisel 来写 Difftest 以及 SoC，其接入 YSYX 框架的原理是：
           先在 Chisel 语言下将处理器核跟 Difftest 模块链接，再将 Chisel 编译成 Verilog，
           在 Verilog 里直接就实现了 Difftest 模块的例化。
         - 若需要在 YSYX 的基础上进行，我们可以先得到其 Verilog 文件，  
           再接入 MCU_core: `mill playground.runMain CPU.rv64_1stage.u_simtop`

      ![](https://s2.loli.net/2023/06/29/JTnzN795uOwBWvQ.png)

   3. 在 **<u>SimTop.v 里例化 MCU_core</u>**，然后通过 Difftest 的 Makefile 文件编译整个工程，可以得到 emu 可执行文件
      1. Difftest 框架规定必须在 **SimTop** 文件里例化 MCU_core，因为 Difftest 的 Makefile 里写死了
      2. Difftest 的 Makefile 编译会首先将 SimTop.v 编译成`VSimTop.h`, `VSimTop.cpp`等文件，
         供后续编译 C++文件调用
      3. Difftest 编译 emu 文件的时候，会引用 VSimTop 等文件以及 nemu-interpreter-so 文件、也会载入 bin 文件以初始化 I-Memory.

# 运行不通过，程序 abort

![image-20230701082440062](https://s2.loli.net/2023/07/01/5cs8iLybhG2EkKN.png)

过去一周按照 YSYX 的 Difftest 测试框架，首先编译 Chisel 文件得到了 Verilog 文件，然后在 VSimTop.v 文件里，接入了我们的 MCU_core；
然后成功编译出了 emu 可执行文件，但是**在执行该 emu 文件的时候，程序并不能正确运行**

经过分析觉得可能的原因有如下两点：

1. SoC Core 结构不同，我们的 I-Memory 是放在 IF 内部的，
   Difftest demo 里的 SoC 其 I-Memory 是放在 Core 外面，通过 bus 读取指令的
   ![](https://s2.loli.net/2023/06/30/RE5kzTPf7BGt2iO.png)

2. I-Memory 架构不同，我们是 2Bank，demo 是 1-bank，
   因此加载 bin 文件的逻辑不同（NEMU 通过 xx 函数载入 bin 文件到其内存中）

   ![image-20230701083353042](https://s2.loli.net/2023/07/01/8Nzq52hxLsHiEPG.png)

   NEMU 加载镜像的过程如下：

   - NMEU 从`init_monitor`这个函数启动，在该函数内部：
     初始化一些 Log 信息，调调用 `init_mem` 函数、用 `init_isa` 函数、调用 `load_img` 函数
   - init_mem 函数主要负责加载默认的镜像文件到 I-Memory
     NEMU 的 I-Memory 有一块数组来表示，init_mem 函数主要的功能是给该数组赋值随机数

     ```c
       // paddr.c
       static uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};
       void init_mem() {

       ...
         srand(time(0));
         uint32_t *p = (uint32_t *)pmem;
         int i;
         for (i = 0; i < (int) (MEMORY_SIZE / sizeof(p[0])); i ++) {
           p[i] = rand();
         }
     ```

   - init_isa 函数主要负责载入默认镜像文件到 NEMU，并且初始化 pc 跟 x0 寄存器
     ![](https://s2.loli.net/2023/06/29/WeSfnj91rPyiZXu.png)
   - load_img 函数的主要功能是将镜像文件载入到 I-Memory 启示位置

     ```c
     // image_laoder.c
     long load_img(char* img_name, char *which_img, uint64_t load_start, size_t img_size) {
         ...
         FILE *fp = fopen(loading_img, "rb");
         Assert(fp, "Can not open '%s'", loading_img);

         size_t size;
         fseek(fp, 0, SEEK_END);
         size = ftell(fp);
         fseek(fp, 0, SEEK_SET);
         if (img_size != 0 && (size > img_size)) {
          Log("Warning: size is larger than img_size(upper limit), please check if code is missing. size:%lx img_size:%lx", size, img_size);
          size = img_size;
         }

         int ret = fread(guest_to_host(load_start), size, 1, fp);
     }
     // emu.cpp
       if (!strcmp(img + (strlen(img) - 4), ".bin")) {  // file extension: .bin
           FILE *fp = fopen(img, "rb");
           if (fp == NULL) {
               printf("Can not open '%s'\n", img);
               assert(0);
           }

           fseek(fp, 0, SEEK_END);
           img_size = ftell(fp);
           if (img_size > EMU_RAM_SIZE) {
               img_size = EMU_RAM_SIZE;
           }

           fseek(fp, 0, SEEK_SET);
           ret = fread(ram, img_size, 1, fp);

           assert(ret == 1);
           fclose(fp);
       }
     ```

   DUT 加载镜像的过程如下：

   - Emulator 构造函数会调用`init_mem`函数

     ![image-20230630175159241](https://s2.loli.net/2023/07/01/7wnKtoasHJedq6G.png)

   - `init_ram`函数会把 image bin 文件内容拷贝到`ram`这个指针所指代的地址

     ```c
     // ram.cpp
     static uint64_t *ram;
     //...
     void init_ram(const char *img) {
       assert(img != NULL);

       printf("The image is %s\n", img);

       // initialize memory using Linux mmap
       printf("Using simulated %luMB RAM\n", EMU_RAM_SIZE / (1024 * 1024));
       ram = (uint64_t *)mmap(NULL, EMU_RAM_SIZE, PROT_READ | PROT_WRITE, MAP_ANON | MAP_PRIVATE, -1, 0);
       if (ram == (uint64_t *)MAP_FAILED) {
         printf("Cound not mmap 0x%lx bytes\n", EMU_RAM_SIZE);
         assert(0);
       }
       //...
     }
     ```

   - ram.v 文件会通过 DPI-C 函数在访问 ram 指针所指的这块地址，实现`dut`读取指令

     ```verilog
     // ram.v
     import "DPI-C" function void ram_write_helper
     (
       input  longint    wIdx,
       input  longint    wdata,
       input  longint    wmask,
       input  bit        wen
     );

     import "DPI-C" function longint ram_read_helper
     (
       input  bit        en,
       input  longint    rIdx
     );

     module RAMHelper(
       input         clk,
       input         en,
       input  [63:0] rIdx,
       output [63:0] rdata,
       input  [63:0] wIdx,
       input  [63:0] wdata,
       input  [63:0] wmask,
       input         wen
     );

       assign rdata = ram_read_helper(en, rIdx); // 通过DPI-C读取指令

       always @(posedge clk) begin
         ram_write_helper(wIdx, wdata, wmask, wen && en); // 通过DPI-C写出指令
       end

     endmodule
     ```

   > 如果需要完成 MCU_core 的 I-Memory 初始化工作，需要“在 IF Stage 的 I-Memory 模块中添加 DPI-C 接口”，“更改 ram.cpp 文件里面的 init_mem 函数，以支持 2-bank ITCM”

# 将MCU_Core介入Difftest做的修改

## 放弃使用香山官方提供的最新的Difftest版本

放弃使用最新版本Difftest的原因如下：

1. 香山最新版本的Github仓库里Difftest只有Scala的版本，无法直接在Verilog中引用
2. 目前最新版本的Difftest**过于复杂**：它支持多核、Cache、Uart、Trap等模块，导致移植MCU_Core到最新版本的Difftest时，需要保证这些模块都真确连线，十分复杂。
   一开始尝试接入最新版本的Difftest，结果调试了一两天还是报错无法看到*有进展的结果*，因此预测将MCU_Core接入到最新版本的Difftest框架中将消耗很久的时间
3. 目前由于没有CSR模块，其实我们的MCU_Core的状态仅有**“PC+Register”**表征，因此Difftest框架只需要在指令提交之后比较PC跟Register即可。
   <u>Difftest核心思想：MCU_Core执行一条指令->Reference Model执行一条指令->比较二者的状态(PC + Register)</u>

> 因此选择了“石峰提供的Difftest”版本，这是他之前做YSYX时接入的Difftest，其实现的效果是：将他设计的单周期RISC-V处理器接入到Difftest框架中，比较其每次提交指令后，Register是否跟Reference Model相同，比较符合我们目前的测试需求，接入的难度相当于接入最新版本的Difftest也更加可控。

## 接入Difftest框架做的修改

![image-20230707211721928](../../../../../../Pictures/typora/image-20230707211721928.png)

为了将MCU_Core接入到Difftest框架，主要做了如下修改：

1. 修改Verilog代码接入Difftest框架之后的Warning，主要包括代码中的“隐式变量声明、信号位宽不匹配、模块重定义”等Warning。因为Verilator相较于Iverilog对于语法检查更加严格一些。

2. 在top.v中增加接口，因为：

   - Difftest框架需要知道MCU_Core的一些内部信号，如pc, instruction
   - 将一些重要的信号从top引出来，可以在Difftest的时候进行打印，方便判断

   ```verilog
   // mcu_core/top.v
   module top(
       input  wire        clk,
       input  wire        resetn,
       // signals used by difftest
       output wire [31:0] pc,
       output wire [63:0] instr,
       output wire        wb_en,
       output wire [ 4:0] wb_idx,
       output wire [31:0] wb_data,
       output wire [31:0] id_instr,
       output wire [20:0] op_code,
       output wire [31:0] src1,
       output wire [31:0] src2,
       output wire [ 3:0] wb_src,
       output wire [31:0] alu_result
       // signals used by difftest
   );
   ```

   ```c
   // difftest/csrc/cpu_exec.c
   static void execute(uint64_t n) {
     for (;n > 0; n --) {
       g_nr_guest_inst ++;

       printf("Top: instr = 0x%x\n", top->instr);
       printf("ID Stage: id_instr=0x%x, opcode = %d, src1 = 0x%x, src2 = 0x%x, wb_src= %d\n", top->id_instr, top->op_code, top->src1, top->src2, top->wb_src);
       printf("EXE stage: alu_result = 0x%x\n", top->alu_result);
       printf("WB Stage: wb_en=%d, idx=%d, data=%x\n", top->wb_en,
              top->wb_idx, top->wb_data);

   ```

   ```bash
   # Difftest仿真输出
   Top: instr = 0x413
   ID Stage: id_instr=0x413, opcode = 1, src1 = 0x0, src2 = 0x0, wb_src= 1
   EXE stage: alu_result = 0x0
   WB Stage: wb_en=0, idx=0, data=0
   npc read instr
   Read I-Memory: addr = 0x80000004, ins= 0x00009117
   NO.2-> pc: 0x80000004, instr: 0x9117, asm: auipc        sp, 9
   NO.2-> pc: 0x80000004, instr: 0x9117, asm: auipc        sp, 9
   C-> pmem_read 80000000: 0x0
   Read I-Memory: addr = 0x80000000, ins= 0x00000413
   pmem_read_rtl: raddr = 0x80000000, rdata= 413
   ```

   如上所示，我们在top的接口中定义了一些信号，我们在Difftest框架中就可以打印相应的信号值

3. 确定MCU_Core提交到difftest 的时机

   - 由于Reference Model是单周期的处理器，其每个Cycle就会提交一条指令；我们的MCU_Core是5级流水线处理器，第一条指令必须等到5个Cycle之后其结果才会写入到Register
   - 我们的MCU由于分支预测器的存在，可能会取一条指令，但是这条指令会被冲刷，因此其不会写入到Register

   可见**MCU_Core中的指令，并不是每一个Cycle都会写入到Register，但是Reference Model一旦执行一条指令，则会在一个Cycle写入到Register**，因此：

   - MCU_Core必须告诉Difftest框架，其在某时刻写入到了Register
   - Difftest框架在收到该信号之后，令Reference Model执行一步，并且将其结果写入到Register

   经过分析发现，我们的MCU_Core不论指令流是何种情况，其在写入Register的时候，都会有wb_en信号为高，因此**我们在top中加入该信号，并且在Difftest中根据该信号来控制Reference Model执行和Difftest比较**。

   ```c
   // difftest/csrc/cpu_exec.c
   /* difftest begin */
   cpu.pc = top->pc; // pc存入cpu结构体
   dump_gpr(); // 寄存器值存入cpu结构体
   if(top->wb_en){ // <- 判断指令提交再进入Difftest
       difftest_step(top->pc);
   }
   /* difftest end */
   ```

4. 在I-Memory中增加DPI-C函数实现I-Memory初始化

   - 不同于用verilog写的testbench，Difftest框架里初始化都是通过c函数来将编译好的二进制文件读入内存的。
     - 在Difftest代码里，定义了一块内存`pmem`用于存储MCU_Core的指令
     - 通过load_img函数来初始化pmem，实现I-Memory的初始化；在verilog写的testbench中，我们是通过readmemh函数来读入二进制文件到内存的
     - 在verilog文件中，**指令的读取是通过DPI-C函数，读取`pmem`对应地址的值**；在verilog写的testbench中，指令的读取是直接通过`assign instr = i-memory[addr];`来实现的

   ![image-20230707211024214](https://s2.loli.net/2023/07/07/adIbS1DR5uxBA4r.png)

5. 在Register中增加DPI-C函数将CPU的register传递给Difftest模块

   ```verilog
   import "DPI-C" function void set_gpr_ptr(input logic [63:0] a []); // add DPI-C function
   module regfile
       (
       input  wire                              clk_i,
       input  wire                              resetn_i,

       output wire    [REG_DATA_WIDTH-1 :0]     rs1_data_o, // rd1
       //....
       );
   	//.....
       // regfile其余部分均保持不变即可
       //.....

       initial set_gpr_ptr(regfile_data); // <- 使用该DPI-C函数将mcu_core的register状态传递给Difftest模块

   endmodule
   ```

   ![image-20230707210809687](https://s2.loli.net/2023/07/07/hjYRv8Ps32GOZTV.png)

## MCU_Core接入Difftest结果

![image-20230707210706875](https://s2.loli.net/2023/07/07/QD8nlf1BTNMxYGo.png)

目前MCU_Core已经接入到了Difftest框架，Difftest检测到MCU_Core运行的结果跟Reference Model的结果不同，会报错，并且给出报错的信息，如上图所示。

1. 后续会陆续根据Difftest的提示，陆续修改MCU_Core中的bug，直到通过所有的测试，达到如下图所示效果，出现`HIT GOOD TRAP`字样：

   ![image-20230707210602556](https://s2.loli.net/2023/07/07/nmXbVy69HxjOtwJ.png)

2. 也会预先研究如何在Difftest中测试一些复杂事件的比较，例如Trap、CSR比较

## References

1. [RISC-V 及 RISC-V core compliance test 简析](https://zhuanlan.zhihu.com/p/232088281)
2. [RISC-V Compliance Tests](https://github.com/lowRISC/riscv-compliance/blob/master/doc/README.adocintroduction)
3. [Imperas Test Suit](https://github.com/riscv-ovpsim/imperas-riscv-tests)
4. [riscv-arch-test](https://github.com/riscv-non-isa/riscv-arch-test)
5. [mill 配置教程](https://alvinalexander.com/scala/mill-build-tool/step-1-hello-world/)
6. [chisel3 基础知识](https://inst.eecs.berkeley.edu/~cs250/sp17/handouts/chisel-tutorial.pdf)
7. [chisel3 高级语法](https://inst.eecs.berkeley.edu/~cs250/sp17/handouts/advanced-chisel.pdf)
8. [🌟Difftest 踩坑笔记(二)](http://www.icfgblog.com/index.php/software/341.html#comment-61)
9. [🌟Verilog 代码接入到 Difftest](https://github.com/OSCPU/ysyx/issues/9)
10. [🌟Chisel 接入 difftest 的几个主要步骤](https://github.com/OSCPU/ysyx/issues/8)
11. [🌟Difftest 使用指南](https://github.com/OpenXiangShan/difftest/blob/master/doc/usage.md)
12. [difftest 访存踩坑分享](https://github.com/OSCPU/ysyx/issues/10)
13. [Difftest 和 NEMU 的版本对应关系](https://github.com/OSCPU/ysyx/issues/13)
14. [🌟chiplab's documentation](https://chiplab.readthedocs.io/zh/latest/)
