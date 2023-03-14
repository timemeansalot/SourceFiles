---
title: RV-32IM处理器流水线设计
date: 2023-03-13 16:02:35
tags: RISCV
---

![Basic five-stage pipeline in a RISC machine](https://s2.loli.net/2023/03/13/7GPzH91tmwkxvEC.png)
RISCV 5 级流水线设计，支持 RV-32IM 指令集

<!--more-->

RV-32I 中设计到的 load/store 指令有如下 8 条:

- LB
- LH
- LW
- LBU
- LHU
- SB
- SH
- SW

| Instruction | Assemble Code Demo    | Type   | Math Description                                    |
| ----------- | --------------------- | ------ | --------------------------------------------------- |
| LB          | `lb rd, (offset)rs1`  | I-Type | $x[rd]=signExt(M[x[rs1]+signExt(offset)]_{[7:0]})$  |
| LH          | `lh rd, (offset)rs1`  | I-Type | $x[rd]=signExt(M[x[rs1]+signExt(offset)]_{[15:0]})$ |
| LW          | `lw rd, (offset)rs1`  | I-Type | $x[rd]=M[x[rs1]+signExt(offset)]_{[31:0]}$          |
| LBU         | `lbu rd, (offset)rs1` | I-Type | $x[rd]=Ext(M[x[rs1]+signExt(offset)]_{[7:0]})$      |
| LHU         | `lhu rd, (offset)rs1` | I-Type | $x[rd]=Ext(M[x[rs1]+signExt(offset)]_{[15:0]})$     |
| SB          | `sb rs2, offset(rs0)` | S-Type | $M[x[rs1]+signExt(offset)]=x[rs2]_{[7:0]}$          |
| SH          | `sh rs2, offset(rs0)` | S-Type | $M[x[rs1]+signExt(offset)]=x[rs2]_{[15:0]}$         |
| SW          | `sw rs2, offset(rs0)` | S-Type | $M[x[rs1]+signExt(offset)]=x[rs2]_{[31:0]}$         |

> S-Type 里没有 rd 寄存器

# Load 指令

Load 指令编码格式:

| 31, 20       | 19, 15 | 14, 12   | 11, 7 | 6, 0    |
| ------------ | ------ | -------- | ----- | ------- |
| imm[11:0]    | rs1    | funct3   | rd    | opcode  |
| offset[11:0] | base   | 000->101 | dest  | 0000011 |

load 指令的 opcode 都是`0000011`, 5 条 load 指令的区别在于 funct3 不同:

|     | funct3 |
| --- | ------ |
| LB  | 001    |
| LH  | 010    |
| LW  | 011    |
| LBU | 100    |
| LHU | 101    |

load 指令有 5 条, load 指令都是 I-Type 的指令，其功能是：从 memory 中取出 data 放到 RF(register file)中，具体每个 Stage 执行的操作如下：

- ID(Instruction Decode):
- EXE(Execution)
- MEM(Memory Access)
- WB(Write Back): 在 clk 上升沿将 memory 中读到的数据存入到 x[rd]
- IF(Instruction Fetch): 取下一条 PC 的地址

# Store 指令

Store 指令编码格式:

| 31, 25       | 24, 20 | 19, 15 | 14, 12   | 11, 7       | 6, 0    |
| ------------ | ------ | ------ | -------- | ----------- | ------- |
| imm[11:0]    | rs2    | rs1    | funct3   | imm[4:0]    | opcode  |
| offset[11:5] | src    | base   | 000->010 | offset[4:0] | 0100011 |

Store 指令有 3 条, store 指令的 opcode 都是`0100011`, 3 条 store 指令的区别在于 funct3 不同:

|     | funct3 |
| --- | ------ |
| SB  | 001    |
| SH  | 010    |
| SW  | 011    |

- ID(Instruction Decode):

  1. 将 rs1 送到 RF 的 ad1(address port 1), 从 RF 中读出 base address 放到 rd1(read data1)
  2. 将 rs2 送到 RF 的 ad2(address port 2), 从 RF 中读出 source data 放到 rd2(read data 2)
  3. 将指令中的 imm(imm=inst[31:25, 11:7]) 做立即数拓展为 32bits,得到 extImm.  
     修改 Extend Unit，不能跟 load 通用

- EXE(Execution)
  1. 将 rd1 连接到 ALU 的 src1, 将 extImm 连接到 ALU 的 src2
  2. aluOP=add，做加法，aluResult 的结果是用于访问 Data Memory 的地址 mAddress
- MEM(Memory Access): 在 clk 上升沿的时候将 ad2 写入到 data memory
  1. 将 mAddress 连接到 data memory 的 ad
  2. 将 rd2 连接到 data memory 的 WD
  3. 将 MeMWrite 连接到 Data Memory 的 WE
- WB(Write Back): 在 clk 上升沿将 memory 中读到的数据存入到 x[rd]
  1. 将 extMData 连接到 RF 的 WD(write data)
  2. 将 rAddress 连接到 RF 的 AD3(address 3)
  3. 将 RegWrite 连接到 RF 的 WE(write enable)
- IF(Instruction Fetch): 取下一条 PC 的地址
  1. 在 clk 上升沿将 PC+4 写入到 PC register
