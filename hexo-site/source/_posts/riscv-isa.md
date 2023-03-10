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

检查无符号加法的溢出只需要在指令后添加一个额外的分支指令：

```riscv
addu t0，t1，t2;

bltu t0， t1，overflow
```

对于带符号的加法，如果已知一个操作数的符号，则溢出检查只需要在加法后添加一条分支 指令：

```riscv
addi t0，t1，+ imm;

blt t0，t1，overflow
```

对于一般的带符号加法，我们需要在加法指令后添加三个 附加指令，当且仅当一个操作数为负数时，结果才能小于另一个操作数，否则就是溢出:

```riscv
add t0, t1, t2

slti t3, t2, 0

slt t4,t0,t1

bne t3, t4, overflow
```

RISCV 中涉及到溢出的指令有: `ANDI`, `ADD`, `SUB`

![](https://s2.loli.net/2023/03/10/itwWJOdcnFNysMv.png)

| 5-bit Encoding (rx) | 3-bit Compressed Encoding (rx') | Register | [ABI](https://en.wikichip.org/w/index.php?title=application_binary_interface&action=edit&redlink=1) Name | Description                                                  | Saved by Calle- |
| ------------------- | ------------------------------- | -------- | -------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ | --------------- |
| 0                   | -                               | x0       | zero                                                                                                     | [hardwired zero](https://en.wikichip.org/wiki/zero_register) | -               |
| 1                   | -                               | x1       | ra                                                                                                       | return address                                               | -R              |
| 2                   | -                               | x2       | sp                                                                                                       | stack pointer                                                | -E              |
| 3                   | -                               | x3       | gp                                                                                                       | global pointer                                               | -               |
| 4                   | -                               | x4       | tp                                                                                                       | thread pointer                                               | -               |
| 5                   | -                               | x5       | t0                                                                                                       | temporary register 0                                         | -R              |
| 6                   | -                               | x6       | t1                                                                                                       | temporary register 1                                         | -R              |
| 7                   | -                               | x7       | t2                                                                                                       | temporary register 2                                         | -R              |
| 8                   | 0                               | x8       | s0 / fp                                                                                                  | saved register 0 / frame pointer                             | -E              |
| 9                   | 1                               | x9       | s1                                                                                                       | saved register 1                                             | -E              |
| 10                  | 2                               | x10      | a0                                                                                                       | function argument 0 / return value 0                         | -R              |
| 11                  | 3                               | x11      | a1                                                                                                       | function argument 1 / return value 1                         | -R              |
| 12                  | 4                               | x12      | a2                                                                                                       | function argument 2                                          | -R              |
| 13                  | 5                               | x13      | a3                                                                                                       | function argument 3                                          | -R              |
| 14                  | 6                               | x14      | a4                                                                                                       | function argument 4                                          | -R              |
| 15                  | 7                               | x15      | a5                                                                                                       | function argument 5                                          | -R              |
| 16                  | -                               | x16      | a6                                                                                                       | function argument 6                                          | -R              |
| 17                  | -                               | x17      | a7                                                                                                       | function argument 7                                          | -R              |
| 18                  | -                               | x18      | s2                                                                                                       | saved register 2                                             | -E              |
| 19                  | -                               | x19      | s3                                                                                                       | saved register 3                                             | -E              |
| 20                  | -                               | x20      | s4                                                                                                       | saved register 4                                             | -E              |
| 21                  | -                               | x21      | s5                                                                                                       | saved register 5                                             | -E              |
| 22                  | -                               | x22      | s6                                                                                                       | saved register 6                                             | -E              |
| 23                  | -                               | x23      | s7                                                                                                       | saved register 7                                             | -E              |
| 24                  | -                               | x24      | s8                                                                                                       | saved register 8                                             | -E              |
| 25                  | -                               | x25      | s9                                                                                                       | saved register 9                                             | -E              |
| 26                  | -                               | x26      | s10                                                                                                      | saved register 10                                            | -E              |
| 27                  | -                               | x27      | s11                                                                                                      | saved register 11                                            | -E              |
| 28                  | -                               | x28      | t3                                                                                                       | temporary register 3                                         | -R              |
| 29                  | -                               | x29      | t4                                                                                                       | temporary register 4                                         | -R              |
| 30                  | -                               | x30      | t5                                                                                                       | temporary register 5                                         | -R              |
| 31                  | -                               | x31      | t6                                                                                                       | temporary register 6                                         | -R              |

# RISCV 指令介绍

![RV-32IM Instructions](/Users/fujie/Pictures/typora/riscv-micro-arch/addi.jpg)
![RV-32IM Instructions](/Users/fujie/Pictures/typora/riscv-micro-arch/shiftISA.jpg)
![RV-32IM Instructions](/Users/fujie/Pictures/typora/riscv-micro-arch/R-typeISA.jpg)

> PS: $(xx)_{[31:0]}$表示取 xx 的低 32bits

# Calculation

## LUI

| Instruction | Assemble Code Demo | Type   | Math Description                |
| ----------- | ------------------ | ------ | ------------------------------- |
| LUI         | `lui rd, imm`      | U-Type | $x[rd]=(im<<12+0x000)_{[31:0]}$ |

| 31-27      | 26-25 | 24-20 | 19-15 | 14-12 | 11-7 | 6-2   | 1-0 |
| ---------- | ----- | ----- | ----- | ----- | ---- | ----- | --- |
| imm[31:12] |       |       |       |       | rd   | 01101 | 11  |

`imm`是 20bits 的无符号数，其取值范围是[0,0xfffff]，写汇编指令时如果 imm 超出了这个范围，汇编器会报错`not in range`

## AUIPC

| Instruction | Assemble Code Demo | Type   | Math Description             |
| ----------- | ------------------ | ------ | ---------------------------- |
| AUIPI       | `auipi rd, imm`    | U-Type | $x[rd]=(im<<12+pc)_{[31:0]}$ |

| 31-27      | 26-25 | 24-20 | 19-15 | 14-12 | 11-7 | 6-2   | 1-0 |
| ---------- | ----- | ----- | ----- | ----- | ---- | ----- | --- |
| imm[31:12] |       |       |       |       | rd   | 00101 | 11  |

`imm`是 20bits 的无符号数，其取值范围是[0,0xfffff]，写汇编指令时如果 imm 不超出了这个范围，汇编器会报错 `not in range`

> PS: 之所以`LUI/AUIPC`是 U-Type，是因为它们的 imm 都是按照无符号数 unsigned 方式来对待的

## ADDI

| Instruction | Assemble Code Demo | Type              | Math Description                       |
| ----------- | ------------------ | ----------------- | -------------------------------------- |
| ADDI        | `add rd, rs1, imm` | I-Type            | $x[rd]=(x[rs1]+signExt(imm))_{[31:0]}$ |
| LI          | `li rd, imm`       | pseudoinstruction | $x[rd]=imm_{[31:0]}$<br />             |

| 31-27     | 26-25 | 24-20 | 19-15 | 14-12 | 11-7 | 6-2   | 1-0 |
| --------- | ----- | ----- | ----- | ----- | ---- | ----- | --- |
| imm[11:0] |       |       | rs1   | 000   | rd   | 00100 | 11  |

1. `ADDI`指令中 Imm 一共是 12bits 的有符号数，合法的取值范围是$[-2048, 2047)$，在写汇编代码的时候，如果 imm 不在该范围内则汇编的时候会直接报错`illegal operands`。例如：`addi a0, zero, 2048`汇编的时候会报错。
2. `li rd, imm`：
   - 当$imm\in [-2048, 2047]$的时候，会被翻译成`addi rd, imm`
   - 当$imm\notin [-2048, 2047]$的时候，会被翻译成`lui`+`addi`的指令序列

## ADD

| Instruction | Assemble Code Demo | Type   | Math Description                 |
| ----------- | ------------------ | ------ | -------------------------------- |
| ADD         | `add rd, rs1, rs2` | R-Type | $x[rd]=(x[rs1]+x[rs2])_{[31:0]}$ |

| 31-27 | 26-25 | 24-20 | 19-15 | 14-12 | 11-7 | 6-2   | 1-0 |
| ----- | ----- | ----- | ----- | ----- | ---- | ----- | --- |
| 00000 | 00    | rs2   | rs1   | 000   | rd   | 01100 | 11  |

## SUB

| Instruction | Assemble Code Demo | Type   | Math Description                 |
| ----------- | ------------------ | ------ | -------------------------------- |
| SUB         | `sub rd, rs1, rs2` | R-Type | $x[rd]=(x[rs1]-x[rs2])_{[31:0]}$ |

| 31-27 | 26-25 | 24-20 | 19-15 | 14-12 | 11-7 | 6-2   | 1-0 |
| ----- | ----- | ----- | ----- | ----- | ---- | ----- | --- |
| 01000 | 00    | rs2   | rs1   | 000   | rd   | 01100 | 11  |

# Logic

## OR

| Instruction | Assemble Code Demo | Type   | Math Description                     |
| ----------- | ------------------ | ------ | ------------------------------------ |
| OR          | `or rd, rs1, rs2`  | R-Type | $x[rd]=(x[rs1] \| x[rs2])\_{[31:0]}$ |

| 31-27 | 26-25 | 24-20 | 19-15 | 14-12 | 11-7 | 6-2   | 1-0 |
| ----- | ----- | ----- | ----- | ----- | ---- | ----- | --- |
| 00000 | 00    | rs2   | rs1   | 110   | rd   | 01100 | 11  |

## AND

| Instruction | Assemble Code Demo | Type   | Math Description                  |
| ----------- | ------------------ | ------ | --------------------------------- |
| AND         | `and rd, rs1, rs2` | R-Type | $x[rd]=(x[rs1]\&x[rs2])_{[31:0]}$ |

| 31-27 | 26-25 | 24-20 | 19-15 | 14-12 | 11-7 | 6-2   | 1-0 |
| ----- | ----- | ----- | ----- | ----- | ---- | ----- | --- |
| 00000 | 00    | rs2   | rs1   | 111   | rd   | 01100 | 11  |

## XOR

| Instruction | Assemble Code Demo | Type   | Math Description                        |
| ----------- | ------------------ | ------ | --------------------------------------- |
| XOR         | `xor rd, rs1, rs2` | R-Type | $x[rd]=(x[rs1] \oplus x[rs2])_{[31:0]}$ |

| 31-27 | 26-25 | 24-20 | 19-15 | 14-12 | 11-7 | 6-2   | 1-0 |
| ----- | ----- | ----- | ----- | ----- | ---- | ----- | --- |
| 00000 | 00    | rs2   | rs1   | 100   | rd   | 01100 | 11  |

## ORI

| Instruction | Assemble Code Demo | Type   | Math Description                         |
| ----------- | ------------------ | ------ | ---------------------------------------- |
| ORI         | `or rd, rs1, imm`  | I-Type | $x[rd]=(x[rs1]\|signExt(imm))\_{[31:0]}$ |

| 31-27     | 26-25 | 24-20 | 19-15 | 14-12 | 11-7 | 6-2   | 1-0 |
| --------- | ----- | ----- | ----- | ----- | ---- | ----- | --- |
| imm[11:0] |       |       | rs1   | 110   | rd   | 00100 | 11  |

## ANDI

| Instruction | Assemble Code Demo | Type   | Math Description                        |
| ----------- | ------------------ | ------ | --------------------------------------- |
| ANDI        | `and rd, rs1, imm` | I-Type | $x[rd]=(x[rs1]\&signExt(imm))_{[31:0]}$ |

| 31-27     | 26-25 | 24-20 | 19-15 | 14-12 | 11-7 | 6-2   | 1-0 |
| --------- | ----- | ----- | ----- | ----- | ---- | ----- | --- |
| imm[11:0] |       |       | rs1   | 111   | rd   | 00100 | 11  |

## XORI

| Instruction | Assemble Code Demo | Type   | Math Description                             |
| ----------- | ------------------ | ------ | -------------------------------------------- |
| XORI        | `xor rd, rs1, imm` | I-Type | $x[rd]=(x[rs1]\oplus signExt(imm))_{[31:0]}$ |

| 31-27     | 26-25 | 24-20 | 19-15 | 14-12 | 11-7 | 6-2   | 1-0 |
| --------- | ----- | ----- | ----- | ----- | ---- | ----- | --- |
| imm[11:0] |       |       | rs1   | 100   | rd   | 00100 | 11  |

# Shifter

## SLL

| Instruction | Assemble Code Demo | Type   | Math Description                            |
| ----------- | ------------------ | ------ | ------------------------------------------- |
| SLL         | `sll rd, rs1, rs2` | R-Type | $x[rd]=(x[rs1] << x[rs2]_{[4:0]})_{[31:0]}$ |

| 31-27 | 26-25 | 24-20 | 19-15 | 14-12 | 11-7 | 6-2   | 1-0 |
| ----- | ----- | ----- | ----- | ----- | ---- | ----- | --- |
| 00000 | 00    | rs2   | rs1   | 001   | rd   | 01100 | 11  |

移位的范围截取 rs2 寄存器的低 5 位数据

## SRL

| Instruction | Assemble Code Demo | Type   | Math Description                                      |
| ----------- | ------------------ | ------ | ----------------------------------------------------- |
| SRL         | `srl rd, rs1, rs2` | R-Type | $x[rd]=((unsigned)x[rs1] >> x[rs2]_{[4:0]})_{[31:0]}$ |

| 31-27 | 26-25 | 24-20 | 19-15 | 14-12 | 11-7 | 6-2   | 1-0 |
| ----- | ----- | ----- | ----- | ----- | ---- | ----- | --- |
| 00000 | 00    | rs2   | rs1   | 101   | rd   | 01100 | 11  |

移位的范围截取 rs2 寄存器的低 5 位数据, 高位补 0

## SRA

| Instruction | Assemble Code Demo | Type   | Math Description                                    |
| ----------- | ------------------ | ------ | --------------------------------------------------- |
| SRA         | `sra rd, rs1, rs2` | R-Type | $x[rd]=((signed)x[rs1] >> x[rs2]_{[4:0]})_{[31:0]}$ |

| 31-27 | 26-25 | 24-20 | 19-15 | 14-12 | 11-7 | 6-2   | 1-0 |
| ----- | ----- | ----- | ----- | ----- | ---- | ----- | --- |
| 01000 | 00    | rs2   | rs1   | 101   | rd   | 01100 | 11  |

移位的范围截取 rs2 寄存器的低 5 位数据，高位补 msb

## SLLI

| Instruction | Assemble Code Demo  | Type   | Math Description               |
| ----------- | ------------------- | ------ | ------------------------------ |
| SLLI        | `slli rd, rs1, imm` | I-Type | $x[rd]=(x[rs1]<<imm)_{[31:0]}$ |

| 31-27 | 26-25 | 24-20 | 19-15 | 14-12 | 11-7 | 6-2   | 1-0 |
| ----- | ----- | ----- | ----- | ----- | ---- | ----- | --- |
| 00000 | 0X    | shamt | rs1   | 001   | rd   | 00100 | 11  |

`imm`的取值范围是[0,31],不在该范围会导致汇编器报错`improper shifter amount`

## SRLI

| Instruction | Assemble Code Demo  | Type   | Math Description                         |
| ----------- | ------------------- | ------ | ---------------------------------------- |
| SRLI        | `srli rd, rs1, imm` | I-Type | $x[rd]=((unsigned)x[rs1]>>imm)_{[31:0]}$ |

| 31-27 | 26-25 | 24-20 | 19-15 | 14-12 | 11-7 | 6-2   | 1-0 |
| ----- | ----- | ----- | ----- | ----- | ---- | ----- | --- |
| 00000 | 0X    | shamt | rs1   | 101   | rd   | 00100 | 11  |

`imm`的取值范围是[0,31],不在该范围会导致汇编器报错`improper shifter amount`

## SRAI

| Instruction | Assemble Code Demo  | Type   | Math Description                       |
| ----------- | ------------------- | ------ | -------------------------------------- |
| SRAI        | `srai rd, rs1, imm` | I-Type | $x[rd]=((signed)x[rs1]>>imm)_{[31:0]}$ |

| 31-27 | 26-25 | 24-20 | 19-15 | 14-12 | 11-7 | 6-2   | 1-0 |
| ----- | ----- | ----- | ----- | ----- | ---- | ----- | --- |
| 01000 | 0X    | shamt | rs1   | 101   | rd   | 00100 | 11  |

imm`的取值范围是[0,31],不在该范围会导致汇编器报错`improper shifter amount`

## SLT

| Instruction | Assemble Code Demo | Type   | Math Description                                |
| ----------- | ------------------ | ------ | ----------------------------------------------- |
| SLT         | `slt rd, rs1, rs2` | R-Type | $x[rd]=(signed)x[rs1] < (signed)x[rs2] ? 1 : 0$ |

| 31-27 | 26-25 | 24-20 | 19-15 | 14-12 | 11-7 | 6-2   | 1-0 |
| ----- | ----- | ----- | ----- | ----- | ---- | ----- | --- |
| 00000 | 00    | rs2   | rs1   | 010   | rd   | 01100 | 11  |

## SLTU

| Instruction | Assemble Code Demo  | Type   | Math Description                                    |
| ----------- | ------------------- | ------ | --------------------------------------------------- |
| SLTU        | `sltu rd, rs1, rs2` | R-Type | $x[rd]=(unsigned)x[rs1] < (unsigned)x[rs2] ? 1 : 0$ |

| 31-27 | 26-25 | 24-20 | 19-15 | 14-12 | 11-7 | 6-2   | 1-0 |
| ----- | ----- | ----- | ----- | ----- | ---- | ----- | --- |
| 00000 | 00    | rs2   | rs1   | 011   | rd   | 01100 | 11  |

> PS：对于 SLT\[U\]：硬件实现的时候可以直接用 x[rs1]-x[rs2]，结果的最高 bit 就是要的结果

## SLTI

| Instruction | Assemble Code Demo  | Type   | Math Description                              |
| ----------- | ------------------- | ------ | --------------------------------------------- |
| SLTI        | `slti rd, rs1, imm` | I-Type | $x[rd]=(signed)x[rs1] < signExt(imm) ? 1 : 0$ |

| 31-27     | 26-25 | 24-20 | 19-15 | 14-12 | 11-7 | 6-2   | 1-0 |
| --------- | ----- | ----- | ----- | ----- | ---- | ----- | --- |
| imm[11:0] |       |       | rs1   | 010   | rd   | 00100 | 11  |

Imm 一共是 12bits 的有符号数，合法的取值范围是[-2048, 2047)，在写汇编代码的时候，如果 imm 不在该范围内则汇编的时候会直接报错`illegal operands`。
在进行比较大小的时候，imm 是符号拓展为 32bits，再跟 x[rs1]比较.

## SLTIU

| Instruction | Assemble Code Demo   | Type   | Math Description                          |
| ----------- | -------------------- | ------ | ----------------------------------------- |
| SLTIU       | `sltiu rd, rs1, imm` | I-Type | $x[rd]=(signed)x[rs1] < Ext(imm) ? 1 : 0$ |

| 31-27     | 26-25 | 24-20 | 19-15 | 14-12 | 11-7 | 6-2   | 1-0 |
| --------- | ----- | ----- | ----- | ----- | ---- | ----- | --- |
| imm[11:0] |       |       | rs1   | 011   | rd   | 00100 | 11  |

Imm 一共是 12bits 的有符号数，合法的取值范围是[-2048, 2047)，在写汇编代码的时候，如果 imm 不在该范围内则汇编的时候会直接报错`illegal operands`。

在进行比较大小的时候，imm 是 0 拓展为 32bits，再跟 x[rs1]比较.

> PS：对于 SLTI\[U\]：硬件实现的时候可以直接用 x[rs1]-\{sign\}Ext(imm)，结果的最高 bit 就是要的结果

# Load/Store

## LB

| Instruction | Assemble Code Demo   | Type   | Math Description                                   |
| ----------- | -------------------- | ------ | -------------------------------------------------- |
| LB          | `lb rd, (offset)rs1` | I-Type | $x[rd]=signExt(M[x[rs1]+signExt(offset)]_{[7:0]})$ |

| 31-27        | 26-25 | 24-20 | 19-15 | 14-12 | 11-7 | 6-2   | 1-0 |
| ------------ | ----- | ----- | ----- | ----- | ---- | ----- | --- |
| offset[11:0] |       |       | rs1   | 000   | rd   | 00000 | 11  |

- EXE Stage 计算内存地址：将 offset 符号拓展为 32bits，跟寄存器 rs1 中的地址相加得到内存中的地址 address  
  offset 是 12bits 的有符号数，其取值范围是[-2048, 2047], 写汇编代码的时候如果 offset 超过了该范围，汇编器会报错`illegal operands`
- MEM Stage 按照地址从内存中取数：按照 address 从内存中取 8bits 的数据
- WB Stage 将数存回到 Register File: 将该 8bits 的数据**符号拓展**为 32bits，存到 rd 寄存器中

## LH

| Instruction | Assemble Code Demo   | Type   | Math Description                                    |
| ----------- | -------------------- | ------ | --------------------------------------------------- |
| LH          | `lh rd, (offset)rs1` | I-Type | $x[rd]=signExt(M[x[rs1]+signExt(offset)]_{[15:0]})$ |

| 31-27        | 26-25 | 24-20 | 19-15 | 14-12 | 11-7 | 6-2   | 1-0 |
| ------------ | ----- | ----- | ----- | ----- | ---- | ----- | --- |
| offset[11:0] |       |       | rs1   | 001   | rd   | 00000 | 11  |

- EXE Stage 计算内存地址：将 offset 符号拓展为 32bits，跟寄存器 rs1 中的地址相加得到内存中的地址 address  
  offset 是 12bits 的有符号数，其取值范围是[-2048, 2047], 写汇编代码的时候如果 offset 超过了该范围，汇编器会报错`illegal operands`
- MEM Stage 按照地址从内存中取数：按照 address 从内存中取 16bits 的数据
- WB Stage 将数存回到 Register File: 将该 16bits 的数据**符号拓展**为 32bits，存到 rd 寄存器中

## LW

| Instruction | Assemble Code Demo   | Type   | Math Description                           |
| ----------- | -------------------- | ------ | ------------------------------------------ |
| LW          | `lw rd, (offset)rs1` | I-Type | $x[rd]=M[x[rs1]+signExt(offset)]_{[31:0]}$ |

| 31-27        | 26-25 | 24-20 | 19-15 | 14-12 | 11-7 | 6-2   | 1-0 |
| ------------ | ----- | ----- | ----- | ----- | ---- | ----- | --- |
| offset[11:0] |       |       | rs1   | 010   | rd   | 00000 | 11  |

- EXE Stage 计算内存地址：将 offset 符号拓展为 32bits，跟寄存器 rs1 中的地址相加得到内存中的地址 address  
  offset 是 12bits 的有符号数，其取值范围是[-2048, 2047], 写汇编代码的时候如果 offset 超过了该范围，汇编器会报错`illegal operands`
- MEM Stage 按照地址从内存中取数：按照 address 从内存中取 32bits 的数据
- WB Stage 将数存回到 Register File: 将该 32bits 的数据存到 rd 寄存器中

## LBU

| Instruction | Assemble Code Demo    | Type   | Math Description                               |
| ----------- | --------------------- | ------ | ---------------------------------------------- |
| LBU         | `lbu rd, (offset)rs1` | I-Type | $x[rd]=Ext(M[x[rs1]+signExt(offset)]_{[7:0]})$ |

| 31-27        | 26-25 | 24-20 | 19-15 | 14-12 | 11-7 | 6-2   | 1-0 |
| ------------ | ----- | ----- | ----- | ----- | ---- | ----- | --- |
| offset[11:0] |       |       | rs1   | 100   | rd   | 00000 | 11  |

- EXE Stage 计算内存地址：将 offset 符号拓展为 32bits，跟寄存器 rs1 中的地址相加得到内存中的地址 address  
  offset 是 12bits 的有符号数，其取值范围是[-2048, 2047], 写汇编代码的时候如果 offset 超过了该范围，汇编器会报错`illegal operands`
- MEM Stage 按照地址从内存中取数：按照 address 从内存中取 8bits 的数据
- WB Stage 将数存回到 Register File: 将该 8bits 的数据**0 拓展**为 32bits，存到 rd 寄存器中

## LHU

| Instruction | Assemble Code Demo    | Type   | Math Description                                |
| ----------- | --------------------- | ------ | ----------------------------------------------- |
| LHU         | `lhu rd, (offset)rs1` | I-Type | $x[rd]=Ext(M[x[rs1]+signExt(offset)]_{[15:0]})$ |

| 31-27        | 26-25 | 24-20 | 19-15 | 14-12 | 11-7 | 6-2   | 1-0 |
| ------------ | ----- | ----- | ----- | ----- | ---- | ----- | --- |
| offset[11:0] |       |       | rs1   | 101   | rd   | 00000 | 11  |

- EXE Stage 计算内存地址：将 offset 符号拓展为 32bits，跟寄存器 rs1 中的地址相加得到内存中的地址 address  
  offset 是 12bits 的有符号数，其取值范围是[-2048, 2047], 写汇编代码的时候如果 offset 超过了该范围，汇编器会报错`illegal operands`
- MEM Stage 按照地址从内存中取数：按照 address 从内存中取 16bits 的数据
- WB Stage 将数存回到 Register File: 将该 16bits 的数据**0 拓展**为 32bits，存到 rd 寄存器中

> PS: `LB/LBU`, `LH/LHU`之间的唯一区别在于从内存中取到的数，前者按照符号拓展为 32bits，后者按照 0 扩展扩展为 32bits

## SB

| Instruction | Assemble Code Demo    | Type   | Math Description                           |
| ----------- | --------------------- | ------ | ------------------------------------------ |
| SB          | `sb rs2, offset(rs0)` | S-Type | $M[x[rs1]+signExt(offset)]=x[rs2]_{[7:0]}$ |

| 31-27        | 26-25 | 24-20 | 19-15 | 14-12       | 11-7  | 6-2 | 1-0 |
| ------------ | ----- | ----- | ----- | ----------- | ----- | --- | --- |
| offset[11:5] | rs2   | rs1   | 000   | offset[4:0] | 01000 | 11  |     |

- EXE Stage 计算存数地址 address：offset 符号扩展为 32bits 之后跟 rs1 寄存器里的数据相加得到 address  
  offset 是 12bits 的有符号数，其取值范围是[-2048, 2047], 写汇编代码的时候如果 offset 超过了该范围，汇编器会报错`illegal operands`
- MEM Stage 存数：将 rs2 寄存器里低 8bits 的数据存储到内存 address 中

## SH

| Instruction | Assemble Code Demo    | Type   | Math Description                            |
| ----------- | --------------------- | ------ | ------------------------------------------- |
| SH          | `sh rs2, offset(rs0)` | S-Type | $M[x[rs1]+signExt(offset)]=x[rs2]_{[15:0]}$ |

| 31-27        | 26-25 | 24-20 | 19-15 | 14-12       | 11-7  | 6-2 | 1-0 |
| ------------ | ----- | ----- | ----- | ----------- | ----- | --- | --- |
| offset[11:5] | rs2   | rs1   | 001   | offset[4:0] | 01000 | 11  |     |

- EXE Stage 计算存数地址 address：offset 符号扩展为 32bits 之后跟 rs1 寄存器里的数据相加得到 address  
  offset 是 12bits 的有符号数，其取值范围是[-2048, 2047], 写汇编代码的时候如果 offset 超过了该范围，汇编器会报错`illegal operands`
- MEM Stage 存数：将 rs2 寄存器里低 16bits 的数据存储到内存 address 中

## SW

| Instruction | Assemble Code Demo    | Type   | Math Description                            |
| ----------- | --------------------- | ------ | ------------------------------------------- |
| SW          | `sw rs2, offset(rs0)` | S-Type | $M[x[rs1]+signExt(offset)]=x[rs2]_{[31:0]}$ |

| 31-27        | 26-25 | 24-20 | 19-15 | 14-12       | 11-7  | 6-2 | 1-0 |
| ------------ | ----- | ----- | ----- | ----------- | ----- | --- | --- |
| offset[11:5] | rs2   | rs1   | 010   | offset[4:0] | 01000 | 11  |     |

- EXE Stage 计算存数地址 address：offset 符号扩展为 32bits 之后跟 rs1 寄存器里的数据相加得到 address  
  offset 是 12bits 的有符号数，其取值范围是[-2048, 2047], 写汇编代码的时候如果 offset 超过了该范围，汇编器会报错`illegal operands`
- MEM Stage 存数：将 rs2 寄存器里 32bits 的数据存储到内存 address 中

> S-Type 里没有 rd 寄存器

# Branch

## BEQ

| Instruction | Assemble Code Demo  | Type   | Math Description                                   |
| ----------- | ------------------- | ------ | -------------------------------------------------- |
| BEQ         | `beq rs1, rs2, imm` | B-Type | $if(x[rs1]=x[rs2])\rightarrow PC+=signExt(imm<<1)$ |

| 31-27         | 26-25 | 24-20 | 19-15 | 14-12 | 11-7         | 6-2   | 1-0 |
| ------------- | ----- | ----- | ----- | ----- | ------------ | ----- | --- |
| imm[12\|10:5] |       | rs2   | rs1   | 000   | imm[4:1\|11] | 11000 | 11  |

- EXE Stage 判断是否相等, 比较的时候 x[rs1], x[rs2]当作带符号数
- IF Stage 根据判断的结果选择 PC+=4 或者 PC+=signExt(imm<<1), **写汇编代码的时候 imm 字段实际上是填写的<u>label</u>, 然后由编译器和连接器根据 PC 和 label 实际计算 imm，最后拼成一条 beq 指令**
  > imm 虽然是 12bits，但是**PC 不是加 signExt(Imm)而是 signExt(imm<<1)**,  
  > 因此寻址范围是 PC 附近$\pm$ 4KB.

## BNE

| Instruction | Assemble Code Demo  | Type   | Math Description                                       |
| ----------- | ------------------- | ------ | ------------------------------------------------------ |
| BNE         | `bnq rs1, rs2, imm` | B-Type | $if(x[rs1]\neq x[rs2])\rightarrow PC+=signExt(imm<<1)$ |

| 31-27         | 26-25 | 24-20 | 19-15 | 14-12 | 11-7         | 6-2   | 1-0 |
| ------------- | ----- | ----- | ----- | ----- | ------------ | ----- | --- |
| imm[12\|10:5] |       | rs2   | rs1   | 001   | imm[4:1\|11] | 11000 | 11  |

## BLT

| Instruction | Assemble Code Demo  | Type   | Math Description                                      |
| ----------- | ------------------- | ------ | ----------------------------------------------------- |
| BNE         | `bnq rs1, rs2, imm` | B-Type | $if(x[rs1]\lt x[rs2])\rightarrow PC+=signExt(imm<<1)$ |

| 31-27         | 26-25 | 24-20 | 19-15 | 14-12 | 11-7         | 6-2   | 1-0 |
| ------------- | ----- | ----- | ----- | ----- | ------------ | ----- | --- |
| imm[12\|10:5] |       | rs2   | rs1   | 100   | imm[4:1\|11] | 11000 | 11  |

## BGE

| Instruction | Assemble Code Demo  | Type   | Math Description                                      |
| ----------- | ------------------- | ------ | ----------------------------------------------------- |
| BNE         | `bnq rs1, rs2, imm` | B-Type | $if(x[rs1]\ge x[rs2])\rightarrow PC+=signExt(imm<<1)$ |

| 31-27         | 26-25 | 24-20 | 19-15 | 14-12 | 11-7         | 6-2   | 1-0 |
| ------------- | ----- | ----- | ----- | ----- | ------------ | ----- | --- |
| imm[12\|10:5] |       | rs2   | rs1   | 101   | imm[4:1\|11] | 11000 | 11  |

## BLTU

| Instruction | Assemble Code Demo  | Type   | Math Description                                                          |
| ----------- | ------------------- | ------ | ------------------------------------------------------------------------- |
| BNE         | `bnq rs1, rs2, imm` | B-Type | $if(unsigned(x[rs1])\le unsigned(x[rs2]))\rightarrow PC+=signExt(imm<<1)$ |

| 31-27         | 26-25 | 24-20 | 19-15 | 14-12 | 11-7         | 6-2   | 1-0 |
| ------------- | ----- | ----- | ----- | ----- | ------------ | ----- | --- |
| imm[12\|10:5] |       | rs2   | rs1   | 110   | imm[4:1\|11] | 11000 | 11  |

- EXE Stage 判断是否小于等于, 比较的时候 x[rs1], x[rs2]当作无符号数
- IF Stage 根据判断的结果选择 PC+=4 或者 PC+=signExt(imm<<1)
  > imm 虽然是 12bits，但是**PC 不是加 signExt(Imm)而是 signExt(imm<<1)**,  
  > 因此寻址范围是 PC 附近$\pm$ 4KB.

## BGEU

| Instruction | Assemble Code Demo  | Type   | Math Description                                                          |
| ----------- | ------------------- | ------ | ------------------------------------------------------------------------- |
| BNE         | `bnq rs1, rs2, imm` | B-Type | $if(unsigned(x[rs1])\ge unsigned(x[rs2]))\rightarrow PC+=signExt(imm<<1)$ |

| 31-27         | 26-25 | 24-20 | 19-15 | 14-12 | 11-7         | 6-2   | 1-0 |
| ------------- | ----- | ----- | ----- | ----- | ------------ | ----- | --- |
| imm[12\|10:5] |       | rs2   | rs1   | 111   | imm[4:1\|11] | 11000 | 11  |

## JAL

| Instruction | Assemble Code Demo | Type   | Math Description                |
| ----------- | ------------------ | ------ | ------------------------------- |
| JAL         | `jal rd, imm`      | J-Type | x[rd]=pc+4, pc+=signExt(imm<<2) |

| 31-27            | 26-25 | 24-20 | 19-15      | 14-12 | 11-7 | 6-2   | 1-0 |
| ---------------- | ----- | ----- | ---------- | ----- | ---- | ----- | --- |
| imm[20\|10:1\|11 |       |       | imm[19:12] |       | rd   | 11011 | 11  |

- EXE Stage 计算 pc+4 的值, aluResult=pc+4
- IF Stage 选择 PC+=signExt(imm<<1), **写汇编代码的时候 imm 字段实际上是填写的<u>label</u>, 然后由编译器和连接器根据 PC 和 label 实际计算 imm，最后拼成一条 beq 指令**
  > imm 虽然是 20bits，但是**PC 不是加 signExt(Imm)而是 signExt(imm<<1)**,  
  > 因此寻址范围是 PC 附近$\pm$ 1MB.
- WB Stage 将 PC+4 的值存入到 rd 中: x[rd]=aluResult

## JALR

| Instruction | Assemble Code Demo  | Type   | Math Description                                |
| ----------- | ------------------- | ------ | ----------------------------------------------- |
| JALR        | `jalr rd, imm(rs1)` | I-Type | x[rd]=pc+4, pc=(x[rs1]+signExt(imm))&0xfffffffe |

| 31-27     | 26-25 | 24-20 | 19-15 | 14-12 | 11-7 | 6-2   | 1-0 |
| --------- | ----- | ----- | ----- | ----- | ---- | ----- | --- |
| imm[11:0] |       |       | rs1   | 000   | rd   | 11001 | 11  |

- EXE Stage 计算 pc+4 的值, aluResult=pc+4
- IF Stage: imm 做符号扩展为 32bits 后跟 x[rs1]相加，然后将最低比特置 0(地址 2Byte 对齐)，得到新的 PC  
  **写汇编代码的时候 imm 字段实际上是填写的<u>label</u>, 然后由编译器和连接器根据 PC 和 label 实际计算 imm，最后拼成一条 beq 指令**
  > imm 虽然是 12bits 有符号数, 因此寻址范围是 PC 附近$\pm$ 1MB.
- WB Stage 将 PC+4 的值存入到 rd 中: x[rd]=aluResult

RV-32IM 涉及到的指令如下图所示：
![RV-32IM Instructions](/Users/fujie/Pictures/typora/riscv-micro-arch/instructions_and_control_signals.png)
![RV-32IM Instructions](/Users/fujie/Pictures/typora/riscv-micro-arch/rv32I-referenceCards.jpg)
ALU 可能执行的操作一共有如下 18 种：

# Logic 单元复用加法器

![1 bit full adder without or gate](https://s2.loli.net/2023/03/10/bBRHtUcKMVNGYQ5.png)
![1 bit full adder with or gate](https://s2.loli.net/2023/03/10/WymKYDeLM1pZHx5.png)

# 32 Shifter Design

[Github 仓库地址](https://github.com/ChipDesign/FAST_INTR_CPU/tree/main/src/rtl)
![](https://s2.loli.net/2023/03/10/CtRza3lUdwKHB7y.png)

RV-32IM 需要实现的移位操作不包括循环移位，只包括：<u>逻辑左移</u>、<u>逻辑右移</u>和<u>算数右移</u>。  
若使用**移位寄存器**来实现移位，每个周期移位是固定的，因此需要多个周期才可以完成移位操作。
![shift01](/Users/fujie/Pictures/typora/riscv-micro-arch/shift01.png)
上图是一个由 4 个 D 触发器构成的简单向右移位寄存器，数据从移位寄存器的左端输入，每个触发器的内容在时钟的上升沿将数据传到下一个触发器。

在 ALU 种需要多数据进行多位移位的操作，采用移位寄存器一次只能移动移位，效率太低；**桶形移位器**采用组合逻辑的方式来实现同时移动多位，在效率上优势极大。因此桶形移位器常被用在于 ALU 中实现移位。

![barrlShifter](/Users/fujie/Pictures/typora/riscv-micro-arch/barrlShifter.jpg)

1. din：待移位待输入数据
2. shift: 移位待位数，有效范围为$[0, \log N-1]$
3. Left/Right: 左移或者右移
4. Arith/Logic：算数右移/逻辑右移
5. dout：移位后的数据

以 4bits din 的 barrlShifter 为例，其 Schematic 如下：

![barrlShift4bits](/Users/fujie/Pictures/typora/riscv-micro-arch/barrlShift4bits.jpg)

- 对于 Nbits 的输入数据，其需要的选择器一共有$\log N$层，每一层共有 N 个选择器，其中第一层选择是否移位 1bit，第二层选择是否移位 2bits，...。
- 对每一个 4 选 1 选择器，其 00 和 10 输入选择未移位后的数据；01 选择右移的数据、11 选择左移的数据。

# 成法器&除法器总结

## 香山

1. 香山的乘法器默认为 3 级流水线的华莱士树乘法器，也可通过配置修改为直接由\*实现的乘法器，再 通过 register retiming 来优化时序。
2. 香山使用了 SRT16 定点除法器 1，每周期运算 4 位，除法循环前后处理各两拍

## 玄铁 C910

MULT 支持 16*16、32*32、64\*64 整数乘法。除法器的设计采用了基 16 的 SRT 算法， 执行周期视操作数而变化
Mult 单元的执行延时为 4 个周期

## ARM A76

乘法 2 ～ 3 周期