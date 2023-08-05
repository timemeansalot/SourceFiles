---
title: 付杰周报-20230805
date: 2023-03-08 14:45:34
tags: RISC-V
---

[TOC]

# 测试通过的 riscv-tests

## 本周通过的测试

1. SLTI
2. SLTIU
3. SRAI
4. SRLI
5. ADD
6. SUB
7. SLT
8. SLTU
9. XOR
10. OR
11. AND
12. SLL
13. SRL
14. SRA
15. LB
16. BH
17. LW
18. LBU
19. LHU
20. SB
21. SH
22. SW

## 所有通过的测试

1. Immdiate Type
   - [x] ADDI
   - [x] SLTI
   - [x] SLTIU
   - [x] XORI
   - [x] ORI
   - [x] ANDI
   - [x] SLLI
   - [x] SRLI
   - [x] SRAI
   - [x] AUIPC
   - [x] LUI
2. Register-Type
   - [x] ADD
   - [x] SUB
   - [x] SLT
   - [x] SLTU
   - [x] XOR
   - [x] OR
   - [x] AND
   - [x] SLL
   - [x] SRL
   - [x] SRA
3. Branch-Type
   - [ ] JALR
   - [ ] JAL
   - [ ] BEQ
   - [ ] BNE
   - [ ] BLT
   - [ ] BGE
   - [ ] BLTU
   - [ ] BGEU
4. Memory-Type
   - [x] LB
   - [x] BH
   - [x] LW
   - [x] LBU
   - [x] LHU
   - [x] SB
   - [x] SH
   - [x] SW
5. Multiple
   - [ ] DIV
   - [ ] DIVU
   - [ ] DIVUW
   - [ ] DIVW
   - [ ] MUL
   - [ ] MULH
   - [ ] MULHSU
   - [ ] MULHU
   - [ ] MULW
   - [ ] REM
   - [ ] REMU
   - [ ] REMUW
   - [ ] REMW
6. Compressed
   - [ ] RVC

# 编译32版本的spike作为reference model

参考了[一生一心第六期的讲义](https://ysyx.oscc.cc/docs/ics-pa/2.4.html#differential-testing)里的makefile，通过`make -nB`可以看到每`make`执行的每一条指令；  
回到之前的difftest 框架中，参考上述的`make`指令即可编译出32bits的spike作为reference model

```bash
    cd nemu/tools/spike-diff
    make -s GUEST_ISA=riscv32 SHARE=1 ENGINE=interpreter # set to build 32 bits version
    mkdir -p repo/build
    cd repo/build && ../configure
    sed -i -e 's/-g -O2/-O2/' repo/build/Makefile
    CFLAGS="-fvisibility=hidden" CXXFLAGS="-fvisibility=hidden"
    cd spike-diff && make
```

除此之外，需要将difftest里CPU_state里的gpr跟pc都更改为32bits位宽

```verilog
    typedef struct {
      // uint64_t gpr[32];
      // uint64_t pc;
      uint32_t gpr[32];
      uint32_t pc;
    } CPU_state;
```

## 对riscv-tests测试集做的修改

1. riscv-tests更改load测试集

   - 问题描述：spike初始化的时候，其Data Memory不是初始化为0, riscv-tests的load相关的测试集在执行load指令之前，都没有往对应的Data Memory地址写入数据，
     导致spike执行load之后会取出spike初始化的Data Memory的值，mcu执行load之后会取出0，二者对不上
     ![](https://s2.loli.net/2023/08/03/xTF8kvfjhaWwoKV.png)
   - 问题解决：修改riscv-tests测试集，在执行之前，执行相应的Store指定往对应地址写入数据，避免spike初始化跟MCU初始化不同，导致load指令读出的结果不同

     ```bash
      diff --git a/code/asm/riscvtest/test_macros.h b/code/asm/riscvtest/test_macros.h
      index 7375715..c748749 100644
      --- a/code/asm/riscvtest/test_macros.h
      +++ b/code/asm/riscvtest/test_macros.h
      @@ -219,6 +219,7 @@ test_ ## testnum: \
           TEST_CASE( testnum, x14, result, \
             li  x15, result; /* Tell the exception handler the expected result. */ \
             la  x1, base; \
      +      sh x15, offset(x1); \
             inst x14, offset(x1); \
           )
  
      @@ -227,7 +228,7 @@ test_ ## testnum: \
             la  x1, base; \
             li  x2, result; \
             la  x15, 7f; /* Tell the exception handler how to skip this test. */ \
      -      sw x0, offset(x1); \
      +      sw x0, 0(x1); \
             store_inst x2, offset(x1); \
             load_inst x14, offset(x1); \
             j 8f; \
      @@ -242,6 +243,8 @@ test_ ## testnum: \
           li  TESTNUM, testnum; \
           li  x4, 0; \
       1:  la  x1, base; \
      +    li x15, result; \
      +    sh x15, offset(x1);\
           inst x14, offset(x1); \
           TEST_INSERT_NOPS_ ## nop_cycles \
           addi  x6, x14, 0; \
      @@ -257,6 +260,8 @@ test_ ## testnum: \
           li  x4, 0; \
       1:  la  x1, base; \
           TEST_INSERT_NOPS_ ## nop_cycles \
      +    li x15, result; \
      +    sh x15, offset(x1);\
           inst x14, offset(x1); \
           li  x7, result; \
           bne x14, x7, fail; \
     ```

2. riscv-tests更改store测试集
   ![](https://s2.loli.net/2023/08/03/ykcImVd7DbUCwYl.png)

   - 问题描述：spike初始化的时候，其Data Memory不是初始化为0，因此在测试`SH`, `SB`等riscv-tests测试集的时候，会出错，如下所示：
      ![](https://s2.loli.net/2023/08/05/tI2ZE5Nb6gahmeD.png)
   - 问题解决：修改riscv-tests测试集，在执行`SH`, `SB`之前，将`0x00000000`通过`SW`写入到Data Memory对应行，避免spike初始化跟MCU初始化不同，导致`LW`读出的结果不同

     ```
       #define TEST_ST_OP( testnum, load_inst, store_inst, result, offset, base ) \
           TEST_CASE( testnum, x14, result, \
             la  x1, base; \
             li  x2, result; \
             la  x15, 7f; /* Tell the exception handler how to skip this test. */ \
             sw x0, 0(x1); /*write 0 to target location first*/ \
             store_inst x2, offset(x1); \
             load_inst x14, offset(x1); \
             j 8f; \
             7:    \
             /* Set up the correct result for TEST_CASE(). */ \
             mv x14, x2; \
             8:    \
           )
     ```

# 本周发现和修复的 bug

1. 移位器msb计算错误

   - [x] bug 已修复
   - bug 描述：移位器默认是右移，左移是通过将`din`对折、取反、再对折来实现的；用右移来实现左移的时候，alu里shifter32的例化方式会导致左移恒补1，进而出错
     ```verilog
     // alu.v
         shifter32 #(32,5) sft(
          .d_in(ain),
          .shift(bin[4:0]),
          .arithOrLogic(srl_op), // SRA or SRL
          .leftOrRight(sra_op|srl_op), // shift left or right
          .d_out(sft_ans));
     // shifter32.v
      assign msbFill=arithOrLogic?0:d_in[DATA_WIDTH-1];
     ```
   - bug 修复：msbFill在左移的时候，必须置0
     ```verilog
     // shifter32.v
         assign msbFill=leftOrRight ? (arithOrLogic?0:d_in[DATA_WIDTH-1]) : 0;
     ```

2. ID Stage没有在译码到Load指令时，未将`is_load`信号发送给hazard unit，导致Load Stall失败

   - [x] bug 已修复
   - bug 描述：ID Stage没有给到hazard unit对应的信号，导致hazard unit无法识别load指令
     ![lw stall failed](https://s2.loli.net/2023/08/03/hYQG37NiyAHgnW1.png)
   - bug 修复：ID需要将对应的信号给到hazard unit

     ```verilog
       // pipelineID.v
      // decode instance
      decoder u_decoder(
          //ports
          .instruction_i  		( instru_32bits  	),
          .alu_op_o        		( aluOperation_o 		),
          .rs1_sel_o       		( rs1_sel_o       		),
          .rs2_sel_o       		( rs2_sel_o       		),
          .imm_type_o      		( imm_type_o      		),
          .branchBType_o  		( branchBType_o  		),
          .branchJAL_o    		( branchJAL_o    		),
          .branchJALR_o   		( branchJALR_o   		),
          .is_load_o              ( is_load_d_o           ),
          .dmem_type_o     		( dmem_type_o     		),
          .wb_src_o        		( wb_src_o        		),
          .wb_en_o         		( wb_en_o         		),
          .instr_illegal_o 		( decoder_instr_illegal )
         );
     ```

3. ID Stage计算指令pc的时候，没有考虑stall的情况
   - [x] bug 已修复
   - bug 描述：ID Stage负责计算每条指令对应的pc，流水线stall的时候，ID Stage依然错误地增加了pc的值，pc的值被打乱之后，所有需要pc进行计算的指令都会出错
     ![pc should stall too](https://s2.loli.net/2023/08/03/H6QN21tXJFbnf7s.png)
   - bug 修复：ID需要输入流水线stall的信号，在stall的时候，将当前的pc固定
     ```verilog
      always @(posedge clk ) begin
          if(~resetn) begin
              pc_instr <= 32'h80000000;
          end
          else if(taken_reg) begin
              pc_instr <= pc_taken;
          end
          else if(~stall_i)begin // pc don't change when stall signal is high
              pc_instr <= pc_next;
          end
      end
     ```
