---
title: RV-32IM处理器流水线设计
date: 2023-03-13 16:02:35
tags: RISCV
---

![Basic five-stage pipeline in a RISC machine](https://s2.loli.net/2023/03/13/7GPzH91tmwkxvEC.png)
RISCV 5 级流水线设计，支持 RV-32IM 指令集

<!--more-->

# 5 级流水线上的功能部件

**Total instructions amount = 37+3 = 40 **

## IF(Instruction Fetch)

### Mux

**功能**：选择下一条 PC

| nextPC                      | instruction amount | relative instructions | source stage |
| --------------------------- | ------------------ | --------------------- | ------------ |
| pc+4                        | 29                 | others                | IF           |
| pc+signExt(offset)          | 7                  | branch(6), JAL        | ID/EXE       |
| x[rs1]+signExt(offset) & ~1 | 1                  | JALR                  | ID/EXE       |


## ID(Instruction Decode)

## EXE(Execution)

## MEM(Memory Access)

## WB(Write Back)

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

load 指令有 5 条, load 指令都是 I-Type 的指令，其功能是：从 memory 中取出 data 放到 RF(register file)中，具体每个 Stage 执行的操作如下：

- ID(Instruction Decode):
- EXE(Execution)
- MEM(Memory Access)
- WB(Write Back): 在 clk 上升沿将 memory 中读到的数据存入到 x[rd]
- IF(Instruction Fetch): 取下一条 PC 的地址

# Store 指令
