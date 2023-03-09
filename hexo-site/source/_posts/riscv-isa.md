---
title: RISCV指令集介绍
date: 2023-03-07 14:58:41
tags: RISCV
---

RV-32IM 每条指令的特性和功能

<!--more-->

# 指令标识位

指令标志位可以用来标志 CPU 的状态，例如 V(overflow)表示溢出，当一条指令的结果出现溢出时，会将 V 置 1，否则置 0.  
例如：`add a0, a1`, a2 表示$a0=a1+a2$, 如果 a1+a2 出现了溢出，则 V 会被置 1.

在 ARM 中，通过 CPSR 寄存器记录各种标识位、在 RISCV 中，没有专门的标志位寄存器，因此需要使用额外的指令来判断。例如，在 RISCV 中判断溢出需要在指令后面添加额外的指令，如：

RISCV 中涉及到溢出的指令有: `ANDI`, `ADD`, `SUB`

# RISCV 指令介绍

> PS: $(xx)_{[31:0]}$表示取 xx 的低 32bits

## LUI

| Instruction | Assemble Code Demo | Type   | Math Description                |
| ----------- | ------------------ | ------ | ------------------------------- |
| LUI         | `lui rd, imm`      | U-Type | $x[rd]=(im<<12+0x000)_{[31:0]}$ |

`LUI`配合`ADDI`可以构造一个 32bits 的数，可以用于构造某个寄存器的值

## ADDI

| Instruction | Assemble Code Demo | Type              | Math Description                       |
| ----------- | ------------------ | ----------------- | -------------------------------------- |
| ADDI        | `add rd, rs1, imm` | I-Type            | $x[rd]=(x[rs1]+signExt(imm))_{[31:0]}$ |
| LI          | `li rd, imm`       | pseudoinstruction | $x[rd]=imm_{[31:0]}$                   |

1. `ADDI`指令中 Imm 一共是 12bits 的有符号数，合法的取值范围是$[-2048, 2047)$，在写汇编代码的时候，如果 imm 不在该范围内则汇编的时候会直接报错。例如：`addi a0, zero, 2048`汇编的时候会报错。
2. `li rd, imm`：
   - 当$imm\in [-2048, 2047]$的时候，会被翻译成`addi rd, imm`
   - 当$imm\notin [-2048, 2047]$的时候，会被翻译成`lui`+`addi`的指令序列

## ADD

| Instruction | Assemble Code Demo | Type   | Math Description                 |
| ----------- | ------------------ | ------ | -------------------------------- |
| ADD         | `add rd, rs1, rs2` | R-Type | $x[rd]=(x[rs1]+x[rs2])_{[31:0]}$ |

## SUB

| Instruction | Assemble Code Demo | Type   | Math Description                 |
| ----------- | ------------------ | ------ | -------------------------------- |
| SUB         | `sub rd, rs1, rs2` | R-Type | $x[rd]=(x[rs1]-x[rs2])_{[31:0]}$ |

------------------------------logic-----------------

## OR

| Instruction | Assemble Code Demo | Type   | Math Description                   |
| ----------- | ------------------ | ------ | ---------------------------------- |
| OR          | `or rd, rs1, rs2`  | R-Type | $x[rd]=(x[rs1] \oplus x[rs2])\_{[31:0]}$ |

## AND

| Instruction | Assemble Code Demo | Type   | Math Description                  |
| ----------- | ------------------ | ------ | --------------------------------- |
| AND         | `and rd, rs1, rs2` | R-Type | $x[rd]=(x[rs1]\&x[rs2])_{[31:0]}$ |

## XOR

| Instruction | Assemble Code Demo | Type   | Math Description                    |
| ----------- | ------------------ | ------ | ----------------------------------- |
| XOR         | `xor rd, rs1, rs2` | R-Type | $x[rd]=(x[rs1] \^ x[rs2])_{[31:0]}$ |

## ORI

| Instruction | Assemble Code Demo | Type   | Math Description                         |
| ----------- | ------------------ | ------ | ---------------------------------------- |
| OR          | `or rd, rs1, imm`  | I-Type | $x[rd]=(x[rs1]\|signExt(imm))\_{[31:0]}$ |

## ANDI

| Instruction | Assemble Code Demo | Type   | Math Description                        |
| ----------- | ------------------ | ------ | --------------------------------------- |
| AND         | `and rd, rs1, imm` | I-Type | $x[rd]=(x[rs1]\&signExt(imm))_{[31:0]}$ |

## XORI

| Instruction | Assemble Code Demo | Type   | Math Description                        |
| ----------- | ------------------ | ------ | --------------------------------------- |
| XOR         | `xor rd, rs1, imm` | I-Type | $x[rd]=(x[rs1]\^signExt(imm))_{[31:0]}$ |
