---
title: 付杰周报-20230708
date: 2023-03-08 14:45:34
tags: RISC-V
---

[TOC]

# 本周发现和修复的 bug

1. Store指令错误选择src1当作写回的数据

   - [x] bug 已修复
   - bug 描述：Store指令选择将src2写入到Data Memory，当前的MCU错误的选择了将src1写回到Data Memory
     ![](https://s2.loli.net/2023/07/27/lOGdqNX4bHM58Za.png)
   - bug 修复：EXE Stage -> MEM Stage都选择src2作为写回到Data Memory的数据

2. 针对Store指令，ID需要将src2的两种可能传递给EXE
   - [x] bug 已修复
   - bug 描述：Store指令需要两个操作：
     1. 计算地址: `addr=src1+imm`
     2. 将src2写回
        当前代码里ID->EXE对于src的选择，要么是寄存器读出的数，要么是立即数拓展，  
        导致**地址计算正确跟取到正确的写回数据只能同时满足一个**
        ![rs2_sel_o wrong](https://s2.loli.net/2023/07/27/2y8uST9NoA4f3CJ.png)
        ![wrong addr](https://s2.loli.net/2023/07/27/r5ZiuoNtmBE7sSO.png)
   - bug 修复：对于ID来说，针对src2需要同时将RF读取值跟立即数拓展同时传递给EXE
     1. EXE利用立即数拓展计算地址
     2. 将RF读取值传递给MEM
3. MEM写入读出必须提前一个周期

   - [x] bug 已修复
   - bug 描述：由于Data Memory写入需要一个周期的延迟，因此EXE必须提前一个cycle给出地址到Data Memory才可以保证Data Memory在MEM State完成数据的写入
   - bug 修复：EXE在遇到Store类型指令时，将其addr, src2, dmem_type都直接给到MEM，不通过pipeline register

4. 非访存指令（除load/store）之外的指令，decoder为设置其访存类型为`DMEM_NO`

   - [x] bug 已修复
   - bug 描述：decoder没有设置非访存指令的访存类型，导致一条访存指令后面的所有非访存指令都可以写入到Data Memory，从而导致写入的数据是错误的数据
     ![lw](https://s2.loli.net/2023/07/27/qU2CM1Da5Hi64Rl.png)
   - bug 修复：在decoder中设置非访存指令不能够访问Data Memory
     ```bash
     diff --git a/npc/vsrc/decoder.v b/npc/vsrc/decoder.v
     index e607eca..66b45f8 100644
     --- a/npc/vsrc/decoder.v
     +++ b/npc/vsrc/decoder.v
     @@ -83,6 +83,7 @@ module decoder(
              instr_illegal_o = 1'b0; // suppose instruction is legal by default.
              wb_src_o = `WBSRC_ALU;  // suppose write back source is from ALU
              wb_en_o = 1'b0; // suppose write back is not enable
     +        dmem_type_o = `DMEM_NO;
              case(opcode)
                  `OPCODE_LOAD  : begin
                      imm_type_o = `IMM_I;
     ```

# 测试通过的 riscv-tests

## 本周通过的测试

1. SW
2. ADDI
3. SLLI
4. AUIPC

## 所有通过的测试

1. Immdiate Type
   - [x] ADDI
   - [ ] SLTI
   - [ ] SLTIU
   - [x] XORI
   - [x] ORI
   - [x] ANDI
   - [x] SLLI
   - [ ] SRLI
   - [ ] SRAI
   - [x] AUIPC
   - [x] LUI
2. Register-Type
   - [ ] ADD
   - [ ] SUB
   - [ ] SLT
   - [ ] SLTU
   - [ ] XOR
   - [ ] OR
   - [ ] AND
   - [ ] SLL
   - [ ] SRL
   - [ ] SRA
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
   - [ ] LB
   - [ ] BH
   - [ ] LW
   - [ ] LBU
   - [ ] LHU
   - [ ] SB
   - [ ] SH
   - [x] SW

## 测试通过截图

### Immdiate-Type

1. ADDI
   ![ADDI](https://s2.loli.net/2023/07/27/ayvf7q5Zsjb24WB.png)
2. SLTI
3. SLTIU
4. XORI
   ![XORI](https://s2.loli.net/2023/07/21/R5YbuGZrDVf6cgj.png)
5. ORI
   ![ORI](https://s2.loli.net/2023/07/21/QPRkNrMflacEoAj.png)
6. ANDI
   ![ANDI](https://s2.loli.net/2023/07/21/VCwrtB6vZhkdTNR.png)
7. SLLI
   ![SLLI](https://s2.loli.net/2023/07/26/SfJrbcljPNHFBTR.png)
8. SRLI
9. SRAI
10. AUIPC
    ![AUIPC](https://s2.loli.net/2023/07/27/6r1gowdD5TSCKZ7.png)
11. LUI
    ![LUI](https://s2.loli.net/2023/07/21/W8MKySYt6eAOnI1.png)

### Register-Type

1. ADD
2. SUB
3. SLT
4. SLTU
5. XOR
6. OR
7. AND
8. SLL
9. SRL
10. SRA

### Branch-Type

1. JALR
2. JAL
3. BEQ
4. BNE
5. BLT
6. BGE
7. BLTU
8. BGEU

### Memory-Type

1. LB
2. BH
3. LW
4. LBU
5. LHU
6. SB
7. SH
8. SW
   ![SW](https://s2.loli.net/2023/07/27/uc3dSQDjxvnhGAO.png)

# 编译32 bits的reference model

## Q: 为什么需要32 bits的reference model?

A: 在进行riscv-tests测试的时候，针对addi, xor等测试集，64 bits的reference model勉强可以用（在使用的时候，针对64bits的reference model，
我们可以取其寄存器低32bits来同MCU进行比较）；  
 但是在遇到sra，srl等指令的时候，就不能这么操作了：因为64bits的reference model，其最高位是跟32bits的MCU是不同的，例如：

```bash
 lui ra, 0x80000
 srli a4, ra, 1 # <- miss match
```

在32bits的MCU上：`ra=0x80000000; a4=0x40000000;`  
 在64bits的Ref上：`ra=0xffffffff80000000; a4=0x7fffffffc0000000;`  
 即使取Ref的低32bits，也会有：`0xc0000000 != 0x40000000`
![must 32](https://s2.loli.net/2023/07/21/myp1vc9XGajgwSP.png)

## 编译32bits reference model遇到的问题

> 目前DIFFTEST框架使用的是64bits的Spike作为reference model，在引入32bits的reference model时做了如下尝试:

1.  尝试编译32bits的NEMU作为reference model，**失败**

    - 在NEMU的[GitHub主页](https://github.com/OpenXiangShan/NEMU/tree/master)上，给出了编译的教程，但是该教程只针对64bits的版本
    - 尝试根据上述教程做修改编译32bits的NEMU作为reference model失败，<u>因为官方给出的NEMU只包含64bits版本的实现</u>
    - 32bits的NEMU没有给出具体实现，因为一直以来*一生一芯*的培养过程当中，主要的培养内容就是让学生实现32bits版本的NEMU，
      因此NEMU自然不会给出32版本的NEMU实现
    - 另一方面，当前使用NEMU编译得到的64bits 的reference model在接入到DIFFTEST框架之后，会出现<u>segment fault</u>，目前还没有debug出原因。

2.  尝试编译32bits的spike作为reference model，没有进展

    - 根据[Spike GitHub主页](https://github.com/riscv-software-src/riscv-isa-sim/tree/master/arch_test_target/spike)
      上的教程，更改了XLEN版本，进行编译，但是编译得到的Spike还是64bits的
      ![spike reference](https://s2.loli.net/2023/07/28/ha4CoZfjxkYJgwz.png)

3.  可行的思路：在查资料的时候找到了[一生一心第六期的讲义](https://ysyx.oscc.cc/docs/ics-pa/2.4.html#differential-testing)，
    <u>该讲义中提到了在编写32bits的NMEU的时候，可以使用Spike作为32bit是的reference moedel</u>，
    所以打算按照该讲义搭建一生一芯第六期的开发环境，然后在该开发环境里生成32bits的Spike reference model。
    ![spike](https://s2.loli.net/2023/07/28/YXyJ9fZIp1mtzlr.png)

> PS：感谢**石峰**同学在搭建Difftest框架时的帮助，例如MCU接入Difftest测试框架、编译Reference Model

## 受reference model导致测试不通过的测试集

1. 右移指令
2. SH, SB
3. 其他未测试过的指令集，也有可能受reference model原因导致测试不通过
