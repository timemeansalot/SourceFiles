---
title: 付杰周报-20230815
date: 2023-03-08 14:45:34
tags: RISC-V
---

[TOC]

# 测试通过的 riscv-tests

## 本周通过的测试

1. mulhsu
2. mulhu
3. rem
4. remu
5. div
6. divu
7. mul
8. mulh
9. rvc

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
   - [x] JALR
   - [x] JAL
   - [x] BEQ
   - [x] BNE
   - [x] BLT
   - [x] BGE
   - [x] BLTU
   - [x] BGEU
4. Memory-Type
   - [x] LB
   - [x] LH
   - [x] LW
   - [x] LBU
   - [x] LHU
   - [x] SB
   - [x] SH
   - [x] SW
5. Multiple
   - [x] DIV
   - [x] DIVU
   - [x] MUL
   - [x] MULH
   - [x] MULHSU
   - [x] MULHU
   - [x] REM
   - [x] REMU
6. Compressed
   - [x] RVC

# 本周发现和修复的 bug

1. 乘法运算`mulh`错误，错误选择了低32bits结果

   - [x] bug 已修复
   - bug 描述：alu错误地选择了乘法器的结果，应该选择高32bits，但是选择了低32bits
     ![](https://s2.loli.net/2023/08/11/51tApYiDzWBdG2b.png)
   - bug 修复：对于`mulh`,`mulhu`, `mulhsu`指令，需要选择乘法器高32bits结果
     ```verilog
     // alu.v
      assign ALUout=  ({32{sub_op|add_op}}&add_ans[31:0])|
              ({32{rem_op|remu_op}}&rem_ans)|
              ({32{div_op|divu_op}}&div_ans) |
              ({32{mul_op}}&mul_low) |
              ({32{mulh_op|mulhsu_op|mulhu_op}}&mul_high) | // bug fix: choose msb, not lsb
              ({32{or_op|and_op|xor_op}}&log_ans) |
              ({32{sll_op|srl_op|sra_op}}&sft_ans) |
              ({32{sltu_op|slt_op}}&{31'b0,add_ans[32]});
     ```

2. alu判断乘法指令类型错误
   - [x] bug 已修复
   - bug 描述：alu错误的判断了`mulhu`跟`mulhsu`，把二者搞反了
     ![](https://s2.loli.net/2023/08/11/J8up1q76ohKHRBf.png)
   - bug 修复：将判断逻辑替换即可
     ```verilog
     diff --git a/src/verification/vsrc/alu.v b/src/verification/vsrc/alu.v
      index c86bb04..29cd15a 100644
      --- a/src/verification/vsrc/alu.v
      +++ b/src/verification/vsrc/alu.v
      @@ -41,8 +41,8 @@ assign slt_op=		ALUop[8];
       assign sltu_op= 	ALUop[9];
       assign mul_op=		ALUop[10];
       assign mulh_op= 	ALUop[11];
      -assign mulhsu_op=	ALUop[12];
      -assign mulhu_op=	ALUop[13];
      +assign mulhu_op=	ALUop[12];
      +assign mulhsu_op=	ALUop[13];
     ```
3. 乘法多计算了一个周期

   - [x] bug 已修复
   - bug 描述：乘法本来应该在四个周期内计算出结果，但是目前乘法由于其state在ID计算，再通过pipeline register传递给EXE stage，
     导致乘法实际上需要5个周期才可以得到对应的结果
     ![](https://s2.loli.net/2023/08/14/kQGqA64f9TXx1tH.png)
   - bug 修复：修改`multi`乘法的时序，将结果提前一个周期计算出来
     ```verilog
     diff --git a/src/verification/vsrc/multi.v b/src/verification/vsrc/multi.v
       index 57fa64b..ce645f0 100644
       --- a/src/verification/vsrc/multi.v
       +++ b/src/verification/vsrc/multi.v
       +wire [63:0] real_calculation;
       +assign real_calculation = ({64{state==2'b11}} & {ans_temp+{mul16ans,32'b0}});
       -assign prod=ans_temp;
       +assign prod=real_calculation;
     ```

4. ID Stage write_back_enable 没有考虑stall的情况
   - [x] bug 已修复
   - bug 描述：ID Stage在执行乘法指令时，应该只在乘法第四个周期才将write_back_enable拉高；
     但是目前ID Stage在前三个周期都将write_back_enable拉高了；
     这样会导致hazard unit错误地计算bypass信号
     ![](https://s2.loli.net/2023/08/14/drBTjoSpCXbWKnz.png)
   - bug 修复：在ID Stage计算write_back_enable的时候，需要判断乘法、除法指令的周期，只在最后一个周期拉高
     ```verilog
     // pipelineID.v
     diff --git a/src/verification/vsrc/pipelineID.v b/src/verification/vsrc/pipelineID.v
     --- a/src/verification/vsrc/pipelineID.v
     +++ b/src/verification/vsrc/pipelineID.v
     +    wire        wb_en_mul_div;
     +    // write back enable with mul and div operation
     +    assign wb_en_mul_div = (~is_m_d_o & ~is_d_d_o & wb_en_o)|
     +                           ( is_m_d_o & (mul_state==2'b11))|
     +                           ( is_m_d_o & div_last);
     -            reg_write_en_d_o  <= wb_en_o;
     +            reg_write_en_d_o  <= wb_en_mul_div;
     -    assign dst_en_d_o=wb_en_o;
     +    assign dst_en_d_o=wb_en_mul_div;
     ```
5. 乘法器计算符号的时候，没有考虑乘数为零的情况

   - [x] bug 已修复
   - bug 描述：乘法器计算的时候，如果有一个乘数为零，其结果的符号位应该为零，
     但是当前乘法器在计算符号位的时候，没有考虑乘数为零的情况，导致符号位计算错误
     ![](https://s2.loli.net/2023/08/14/TdfOKtmP6jwe18i.png)
   - bug 修复：在计算符号位的时候，判断乘数，如果有乘数为零，则强制符号位为零
     ```verilog
           diff --git a/src/verification/vsrc/multi16.v b/src/verification/vsrc/multi16.v
           --- a/src/verification/vsrc/multi16.v
           +++ b/src/verification/vsrc/multi16.v
           @@ -310,10 +310,9 @@ half_adder 	ha30_2_0(.ain(c29_1_0), .bin(s30_1_0), .sout(ans1[30]), .cout(c30_2_
           -assign sign_out=(ss&(ain[15]^bin[15])) |
           +assign sign_out = (ain==0 | bin ==0) ? 0 : (ss&(ain[15]^bin[15])) |
                   (su&ain[15]) 		|
                   (us&bin[15]);
            `endif
     ```

6. 除法器bug
   - [x] bug 已修复
   - bug 描述：当前测试版本除法器bug较多，例如不能正确计算触发结果、结果出现负数时会比正确答案小1；
   - bug 修复：已经上报给淼鸿、并且已经解决所有bug
