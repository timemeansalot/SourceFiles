---
title: RV-32IM处理器流水线设计
date: 2023-03-13 16:02:35
tags: RISCV
---

![Basic five-stage pipeline in a RISC machine](https://s2.loli.net/2023/03/13/7GPzH91tmwkxvEC.png)
RISCV 5 级流水线设计，支持 RV-32IM 指令集

<!--more-->

# 5 级流水线上的功能部件

**Total instructions amount = 37+3 = 40**

## IF(Instruction Fetch)

1. 2x1 Mux：选择下一条 PC

   | nextPC                      | 相关指令数量 | 相关指令       | PC 来源 |
   | --------------------------- | ------------ | -------------- | ------- |
   | pc+signExt(offset)          | 7            | branch(6), JAL | EXE     |
   | x[rs1]+signExt(offset) & ~1 | 1            | JALR           | EXE     |
   | pc+4                        | 29           | others         | IF      |

2. PC register(IF register): 缓存 mux 的 pc
3. instruction memory

## ID(Instruction Decode)

1. data register:
   - 2 组读端口：任何时刻都可以读出
   - 1 组写端口: 在时钟上升沿写入
2. decoder
3. extending unit
4. ID register: 缓存 IF 需要传递给 ID 的数据，如 instruction, PC, PC+4 及 decoder 的控制信号

## EXE(Execution)

1. ALU
2. 3x1 Mux: 实现 bypass
3. Adder：计算 Target PC，跳转结果判断可以复用 ALU
4. Branch Unit: 判断分支跳转是否发生
5. EXE register: 缓存 ID 需要传递给 EXE 的数据

## MEM(Memory Access)

1. data memory
2. MEM register
3. MEM register: 缓存 EXE 需要传递给 MEM 的数据

## WB(Write Back)

1. 4x1 Mxu: 选择写回到 x[rd]的数据(ALU, Imm, PC+4, Memory)
2. WB register: 缓存 MEM 需要传递给 WB 的数据

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

# 访存指令的流水线映射

## Load 指令

load 指令有 5 条, load 指令都是 I-Type 的指令，其编码格式为:

| 31, 20       | 19, 15 | 14, 12   | 11, 7 | 6, 0    |
| ------------ | ------ | -------- | ----- | ------- |
| imm[11:0]    | rs1    | funct3   | rd    | opcode  |
| offset[11:0] | base   | 000->101 | dest  | 0000011 |

1. IF(Instruction Fetch): PC+=4
2. ID(Instruction Decode):
3. EXE(Execution)
4. MEM(Memory Access)
5. WB(Write Back): 在 clk 上升沿将 memory 中读到的数据存入到 x[rd]

## Store 指令

Store 指令有 3 条，都是 S-Type 指令，其编码格式为:

| 31, 25       | 24, 20 | 19, 15 | 14, 12   | 11, 7       | 6, 0    |
| ------------ | ------ | ------ | -------- | ----------- | ------- |
| imm[11:0]    | rs2    | rs1    | funct3   | imm[4:0]    | opcode  |
| offset[11:5] | src    | base   | 000->010 | offset[4:0] | 0100011 |
