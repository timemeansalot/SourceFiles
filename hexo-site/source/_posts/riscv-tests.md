---
title: RISC-V测试
date: 2023-05-15 15:30:47
tags: RISC-V
---

# TODO

1. riscv-tests 文件夹分类

RISC-V 功能测试，保证 RISC-V 处理器功能正确性

> To ensure that the processor implementation is respecting the RISC-V specification,
> you must pass the [riscv-tests](https://github.com/riscv-software-src/riscv-tests) provided by the RISC-V organization.

<!--more-->

Verification Techniques:

- Self Check
  ![image-20230518180136128](/Users/fujie/Pictures/typora/image-20230518180136128.png)

  ![image-20230518180223338](/Users/fujie/Pictures/typora/image-20230518180223338.png)

- Signature Comparison
  ![image-20230518180358981](/Users/fujie/Pictures/typora/image-20230518180358981.png)

  ![image-20230518180427488](/Users/fujie/Pictures/typora/image-20230518180427488.png)

- Trace Log Comparison
  ![image-20230518181857044](/Users/fujie/Pictures/typora/image-20230518181857044.png)

  ![image-20230518191123232](/Users/fujie/Pictures/typora/image-20230518191123232.png)

- Step and Compare

  ![image-20230518191456578](/Users/fujie/Pictures/typora/image-20230518191456578.png)

  ![image-20230518191551454](/Users/fujie/Pictures/typora/image-20230518191551454.png)

- Test Suits

  ![image-20230518191654857](/Users/fujie/Pictures/typora/image-20230518191654857.png)

  ![image-20230518191807987](/Users/fujie/Pictures/typora/image-20230518191807987.png)

- Test Generator

  ![image-20230518191833437](/Users/fujie/Pictures/typora/image-20230518191833437.png)

- Functional coverage

  ![image-20230518192007858](/Users/fujie/Pictures/typora/image-20230518192007858.png)

  ![image-20230518192102398](/Users/fujie/Pictures/typora/image-20230518192102398.png)

- summay

  ![image-20230518192304623](/Users/fujie/Pictures/typora/image-20230518192304623.png)

  ![image-20230518192330765](/Users/fujie/Pictures/typora/image-20230518192330765.png)

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
4. 例：riscv-tests 中对 `ADD` 指令测试三部分功能：

   - asm test source file:

     - 加法操作正确性
     - 源/目的寄存器测试
     - bypass

     ```asm
       # file: rv32ui-p-add.S
       #-------------------------------------------------------------
       # Arithmetic tests
       #-------------------------------------------------------------

       TEST_RR_OP( 2,  add, 0x00000000, 0x00000000, 0x00000000 );
       TEST_RR_OP( 3,  add, 0x00000002, 0x00000001, 0x00000001 );

       ....
       #-------------------------------------------------------------
       # Source/Destination tests
       #-------------------------------------------------------------

       TEST_RR_SRC1_EQ_DEST( 17, add, 24, 13, 11 );
       TEST_RR_SRC2_EQ_DEST( 18, add, 25, 14, 11 );
       TEST_RR_SRC12_EQ_DEST( 19, add, 26, 13 );
       ....
       #-------------------------------------------------------------
       # Bypassing tests
       #-------------------------------------------------------------

       TEST_RR_DEST_BYPASS( 20, 0, add, 24, 13, 11 );
       TEST_RR_DEST_BYPASS( 21, 1, add, 25, 14, 11 );
       TEST_RR_DEST_BYPASS( 22, 2, add, 26, 15, 11 );
       ...
       TEST_RR_ZERODEST( 38, add, 16, 30 );
     ```

     ```assembly
       # file: test_macros.h
       #define TEST_CASE( testnum, testreg, correctval, code... ) \
           test_ ## testnum: \
               li  TESTNUM, testnum; \
               code; \
               li  x7, MASK_XLEN(correctval); \
               bne testreg, x7, fail;

       #define TEST_RR_OP( testnum, inst, result, val1, val2 ) \
           TEST_CASE( testnum, x14, result, \
             li  x1, MASK_XLEN(val1); \
             li  x2, MASK_XLEN(val2); \
             inst x14, x1, x2; \

       #define RVTEST_FAIL                                                     \
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
       # file: rv32ui-p-add.dump
       # init system like reset RF, set trap vectors
       ...
       # test codes
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
       80000380:	00120213          	add	tp,tp,1 # 1 <_start-0x7fffffff>
       80000384:	00200293          	li	t0,2
       80000388:	fe5214e3          	bne	tp,t0,80000370 <test_20+0x8>
       8000038c:	01800393          	li	t2,24
       80000390:	2c731e63          	bne	t1,t2,8000066c <fail>

       # test fail operations
       8000066c <fail>:
       8000066c:	0ff0000f          	fence
       80000670:	00018063          	beqz	gp,80000670 <fail+0x4>
       80000674:	00119193          	sll	gp,gp,0x1
       80000678:	0011e193          	or	gp,gp,1
       8000067c:	05d00893          	li	a7,93
       80000680:	00018513          	mv	a0,gp
       80000684:	00000073          	ecall
       # all test pass operations
       80000688 <pass>:
       80000688:	0ff0000f          	fence
       8000068c:	00100193          	li	gp,1 # all test fass, set x3 to 1
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
        ~TESTCASE:                                                                                                                                                                                /Users/fujie/Desktop/Developer/git_repos/hbird/e203_hbirdv2/vsim/run/../../riscv-tools/riscv-tests/isa/generated/rv32ui-p-add ~~~~~~~~~~~~~
        ~~~~~~~~~~~~~~Total cycle_count value:      23205 ~~~~~~~~~~~~~
        ~~~~~~~~~~The valid Instruction Count:      14117 ~~~~~~~~~~~~~
        ~~~~~The test ending reached at cycle:      23165 ~~~~~~~~~~~~~
        ~~~~~~~~~~~~~~~The final x3 Reg value:          7 ~~~~~~~~~~~~~
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        ~~~~~~~~~~~~~~~~ TEST_FAIL ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        ~~~~~~~~~~######    ##       #    #     ~~~~~~~~~~~~~~~~
        ~~~~~~~~~~#        #  #      #    #     ~~~~~~~~~~~~~~~~
        ~~~~~~~~~~#####   #    #     #    #     ~~~~~~~~~~~~~~~~
        ~~~~~~~~~~#       ######     #    #     ~~~~~~~~~~~~~~~~
        ~~~~~~~~~~#       #    #     #    #     ~~~~~~~~~~~~~~~~
        ~~~~~~~~~~#       #    #     #    ######~~~~~~~~~~~~~~~~
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     ```

5. riscv-tests 的缺点
   - 测试某一个指令的时候，其生成的测试程序也涉及到其他的指令，
     在处理器核支持的指令不全面的时候，这个方法不可用

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
