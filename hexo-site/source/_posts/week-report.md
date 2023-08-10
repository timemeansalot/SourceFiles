---
title: 付杰周报-20230812
date: 2023-03-08 14:45:34
tags: RISC-V
---

[TOC]

# 测试通过的 riscv-tests

## 本周通过的测试

1. jalr
2. jal
3. beq
4. bne
5. blt
6. bge
7. bltu
8. bgeu
9. mul

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
   - [ ] DIV
   - [ ] DIVU
   - [x] MUL
   - [ ] MULH
   - [ ] MULHSU
   - [ ] MULHU
   - [ ] REM
   - [ ] REMU
6. Compressed
   - [ ] RVC

# 回归测试

> 之前测试riscv-tests时都是手动在Makefile里指定要测试的测试集，测试集不通过时会发现bug；一直修改bug直到通过测试集；
> 为了避免修改之后之前通过的测试集反而通过不了了，每次修改之后都应该把所有的测试集跑一遍，保证之前通过的测试集依然能够通过

## 目录结构介绍

```bash
    ├── build
    ├── csrc
    ├── dump.vcd
    ├── Makefile
    ├── README.md
    ├── result.log
    ├── riscvtest
    ├── so
    └── vsrc
```

本目录格式如上所示，各个部分介绍如下：

1. build：执行make命令后会编译可执行文件跟中间文件，这些文件都放在build目录下
2. csrc：difftest相关的代码
3. vsrc：MCU的所有verilog文件
4. riscvtest：汇编测试文件，在该目录下可以编译所有的汇编文件得到可执行的bin文件
5. so：golden reference存放目录，该目录下有32位的spike.so文件
6. result.log：对所有的riscvtest测试集做回归方针，每个测试集是否通过会记录在该文件下
7. dump.vcd：波形图

## 编译汇编文件

1. 进入到riscvtest目录下
2. 编译一个文件：在其Makefile中用EXEC指定想要编译的汇编文件名
   - `make`：编译该汇编文件得到elf文件，并且得到bin文件
   - `make code`：查看反汇编文件的内容
3. 编译所有文件: `make getAll`

## 仿真测试

1. 进入到verification目录下
2. 测试一个测试集：在Makefile中用IMG指定想要测试的测试集，然后`make run`即可运行difftest，并且进入到debug模式
   - `si`可以进行单步调试，逐行执行指令
   - `c`可以执行所有指令，直到所有指令执行完毕、或者出现错误
3. 回归测试（测试所有测试集）：
   ```bash
   make test_all
   ```
   所有测试集通过的情况会记录在`result.log`文件中
   
   > PS: <u>测试一个测试集</u>跟<u>测试所有测试集</u>，需要编译的difftest有些许不同，因此在切换测试模式之前，需要先`make clean`

# 本周发现和修复的 bug

1. ID Stage被flush的指令，错误地导致了重定向

   - [x] bug 已修复
   - bug 描述：ID 需要计算重定向pc跟taken，目前ID Stage在计算taken的时候，没有考虑ID Stage的flush信号，
     导致被flush的指令，其静态分支预测的地址，被作为重定向pc，取到了错误的指令
     ```verilog
     // pipelineID.v
     assign taken_d_o = ~resetn_delay | ptnt_e_i | redirection_e_i | taken;
     ```
     ![](https://s2.loli.net/2023/08/09/rzw7EYG4XlmuSbZ.png)
   - bug 修复：在计算taken的时候，必须考虑flush信号
     ```verilog
     // pipelineID.v
     assign taken_d_o = ~resetn_delay | ptnt_e_i | redirection_e_i | (~flush_i & taken );
     ```

2. 乘法指令产生的stall，没有正确地被拉低

   - [x] bug 已修复
   - bug 描述：乘法指令执行4个周期，因此需要stall流水线，目前代码里乘法指令stall不能够正确的
     被拉低，导致后续指令一直stall。
     其原因在于hazard unit的代码里，通过`is_m`跟`fin`来判断乘法执行的执行状态，
     但是`fin`为高的时候，前面的`is_m`也是为高，所以`Linst_st_keep`一直为高
     ```verilog
        // hazard.v
       if((~flush)&(is_d|is_m))
       begin
         Linst_st_keep<=1'b1;
       end
       else if(fin)
       begin
         Linst_st_keep<=1'b0;
       end
     ```
   - bug 修复：将`fin`的判断放到前面去，这样`Linst_st_keep`可以被正确地拉低
     ```verilog
        // hazard.v
       if(fin)
       begin
         Linst_st_keep<=1'b0;
       end
       else if((~flush)&(is_d|is_m))
       begin
         Linst_st_keep<=1'b1;
       end
     ```

3. 乘法状态机不是从0开始，从1开始，导致周期错误

   - [x] bug 已修复
   - bug 描述：如下面波形图所示，执行完一个乘法之后，其下一次乘法的状态机不是从0开始，
     是从1开始的，导致下次乘法只执行了3个周期
     ![](https://s2.loli.net/2023/08/10/SeQXcm3iGvxhZlP.png)
   - bug 修复：将判断条件从`11`变成`10`，这样每个乘法都是4个周期
     ```verilog
     // pipelineID.v
       else if(aluOperation_o [10]|aluOperation_o [11]|aluOperation_o [12]|aluOperation_o [13])
       begin
           mul_state<=mul_next_state; 
           if(mul_state==2'b10) // bug fix
           begin
               fin<=1'b1;
           end
           else
           begin
               fin<=1'b0;
           end
       end
     ```
