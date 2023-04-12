---
title: RISC-V压缩指令集
date: 2023-04-10 19:58:24
tags: RISCV
---

![RV-32C](https://s2.loli.net/2023/04/10/C73opKyZbMJrktW.png)
RISC-V 压缩指令集学习笔记

<!--more-->

## RISC-V 压缩指令基础

1. RV32I 会在下述情况下压缩指令，生成 RISC-V 压缩指令(RVC)

   1. imm, offset 很小的时候
   2. register 是 x0 或者 x2
   3. register 是常用的那 8 个: x8~x15
   4. rs1=rd

2. RVC 中的指令大致可以分为如下三类:

   1. Load and Store(4): `LW`, `SW`, `LWSP`, `SWSP`
   2. Control(6): `J`, `JAL`, `JR`, `JALR`, `BEQZ`, `BNEZ`
   3. Integer:
      - Register-Immediate(9): `LI`, `LUI`, `ADDI`, `ADDI16SP`, `ADDI4SPN`, `SLLI`, `SRLI`, `SRAI`, `ANDI`
      - Register-Register(6): `MV`, `AND`, `OR`, `XOR`, `SUB`, `ADD`
      - Others(3): `NOP`, `EBREAK`, `HINT`

3. RV-32IM 中没有对应压缩指令的指令：

   | $opcode_{[6:2]}$ | Instruction Type | Relative Instructions                          |
   | ---------------- | ---------------- | ---------------------------------------------- |
   | 00101            | U-Type           | AUIPC                                          |
   | 01000            | S-Type           | SB, SH                                         |
   | 00000            | I-Type           | LB, BH, LBU, LHU                               |
   | 00100            | I-Type           | SLTI, SLTIU, XORI, ORI                         |
   | 01100            | R-Type           | SLT, SLTU, SLLI, SRLI, SRAI                    |
   | 11000            | B-Type           | BLT, BGE, BLTU, BGEU                           |
   | 01100            | RV-M             | MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU |

## 压缩指令格式

### C.LW 格式举例

| 15-13 | 12-10     | 9-7  | 6-5        | 4-2 | 1-0 |
| ----- | --------- | ---- | ---------- | --- | --- |
| 010   | uimm[5:3] | rs1' | uimm[2\|6] | rd' | 00  |

1. `LW` for _load word_, 是`CL`格式的压缩指令
2. 功能：`x[8+rd’] = sext(M[x[8+rs1’] + uimm][31:0])`
3. 扩展成 32bits 指令：`c.lw rd’,uimm(rs1’) --> lw rd’,offset[6:2](rs1’)`
   - imm 占 5bits，imm 乘 4，**零扩展**为 32bits
   - rs1'和 rd'都是寄存器的下标，只有 3bits，其可以索引 x8~x15 的寄存器

由于 RVC 指令的格式、功能比较固定，且官方的手册已经说的足够精简了，因此本文档不再专门逐一总结其余 26 条 RV32I 相关的 RVC 指令，请参考以下链接自行阅读：

1. 🌟[Official: “C” Standard Extension for Compressed Instructions, Version 2.0 ](https://five-embeddev.com/riscv-isa-manual/latest/c.html)
2. [RV32C, RV64C Instructions on riscv-isa-page](https://msyksphinz-self.github.io/riscv-isadoc/html/rvc.html)

### 恢复成 RV32I 指令

> RVC 恢复成 RV32I 指令的时候，首先根据 op 部分对指令进行分类，再根据 funct3 部分对指令分类。如果多个指令 op 和 funct3 都相同，则需要进一步根据其它字段来区分他们

#### op=00

| 压缩指令 | op=inst[1:0] | funct3=inst[15:13] | 压缩指令格式 | 对应 32I 指令               |
| -------- | ------------ | ------------------ | ------------ | --------------------------- |
| ADDI4SPN | 00           | 000                | CIW          | `addi rd’,x2,nzuimm`        |
| LW       | 00           | 010                | CL           | `lw rd’,offset[6:2](rs1’)`  |
| SW       | 00           | 110                | CS           | `sw rs2’,offset[6:2](rs1’)` |

op=00 时，如果 funct3 不是上述 3 种情况，则都是非法压缩指令

#### op=01

| 压缩指令 | op=inst[1:0] | funct3=inst[15:13] | 压缩指令格式 | 对应 32I 指令             |
| -------- | ------------ | ------------------ | ------------ | ------------------------- |
| ADDI     | 01           | 000                | CI           | `addi rd, rd, nzimm[5:0]` |
| NOP      | 01           | 000                | CI           | `addi x0, x0, 0`          |
| JAL      | 01           | 001                | CJ           | `jal x1, offset[11:1]`    |
| LI       | 01           | 010                | CI           | `addi rd,x0,imm[5:0]`     |
| ADDI16SP | 01           | 011                | CI           | `addi x2,x2, nzimm[9:4]`  |
| LUI      | 01           | 011                | CI           | `lui rd,nzuimm[17:12]`    |
| SRLI     | 01           | 100000             | CB           | `srli rd’,rd’,shamt[5:0]` |
| SRAI     | 01           | 100001             | CB           | `srai rd’,rd’,shamt[5:0]` |
| ANDI     | 01           | 100x10             | CB           | `andi rd’,rd’,imm[5:0]`   |
| SUB      | 01           | 100011             | CA           | `sub rd’,rd’,rs2’`        |
| XOR      | 01           | 100011             | CA           | `xor rd’,rd’,rs2’`        |
| OR       | 01           | 100011             | CA           | `or rd’,rd’,rs2`          |
| AND      | 01           | 100011             | CA           | `and rd’,rd’,rs2’`        |
| J        | 01           | 101                | CJ           | `jal x0,offset[11:1]`     |
| BEQZ     | 01           | 110                | CB           | `beq rs1’,x0,offset[8:1]` |
| BNEZ     | 01           | 111                | CB           | `bne rs1’,x0,offset[8:1]` |

#### op==10

| 压缩指令 | op=inst[1:0] | funct3=inst[15:13] | 压缩指令格式 | 对应 32I 指令            |
| -------- | ------------ | ------------------ | ------------ | ------------------------ |
| SLLI     | 10           | 000                | CI           | `slli rd,rd,shamt[5:0]`  |
| LWSP     | 10           | 010                | CI           | `lw rd,offset[7:2](x2)`  |
| JR       | 10           | 1000               | CR           | `jalr x0,rs1,0`          |
| MV       | 10           | 1000               | CR           | `add rd, x0, rs2`        |
| JALR     | 10           | 1001               | CR           | `jalr x1,rs1,0`          |
| ADD      | 10           | 1001               | CR           | `add rd,rd,rs2`          |
| EBREAK   | 10           | 1001               | CR           | `ebreak`                 |
| SWSP     | 10           | 110                | CSS          | `sw rs2,offset[7:2](x2)` |

![rvc](/Users/fujie/Pictures/typora/rvc.svg)

## 🌟 格式相似的指令

1. `SRLI`、`SRAI`和`ANDI`[11:10]:
   - `SRLI`: 00
   - `SRAI`: 01
   - `ANDI`: 10
2. `J`和`JAL`只有 inst[15]不一样
3. `JR`和`JALR`只有 inst[12]不一样
4. `BNEZ`和`BEQZ`只有 inst[13]不一样

## 🌟 非法指令(illegal instruction)

1. `ADDI4SPN`: $imm == 0$, 被保留了(reserved)
2. `ADDI16SP`: $imm == 0$, reserved
3. `LUI`: $imm == 0$, reserved
4. `SLLI`、`SRLI`和`SRAI`: $imm5=inst[12]==1$，导致移位超过了 31bits
5. `JR`:$rs1 == x0$, `JR`其 offset 恒为 0，若 rs1 还等于 x0, 则跳转 PC 就是当前的 PC
6. 其他未定义的压缩指令也都是 illegal instruction

## 🌟 RVC 的 imm 如何拓展为对应 RV32I 的 imm

1. 立即数做零扩展 (zero-extend imm): `SLLI`, `ADDI4SPN`, `SRLI`, `SRAI`, `SW`, `LW`, `LWSP`, `SWSP`;  
   立即数做符号拓展 (sign-extend imm): Others

   > RVC 中的 imm 的位宽会比 RV32I 指令中的 imm 位宽小，因此需要扩展为对应的位宽.

2. imm 左移位数

   - 1: `J`, `JAL`,`BEQZ`, `BNEZ`
   - 2: `ADDI4SPN`, `LW`, `SW`, `LWSP`, `SWSP`
   - 4: `ADDI16SP`
   - 12: `LUI`

   > RVC 中的 imm 拓展到 RV32I 中的立即数的时候，会有一个放大（scale）倍数，需要对其 imm 进行左移

## 变成其他压缩指令(change to other RVC instruction)

1. `ADDI`: 如果$rd==x0$, 则`ADDI -> NOP`
2. `LUI`: 如果$rd=x2$, 则`LUI -> ADDI16SP`
3. `MV`: 如果$rs2=x0$, 则`MV -> JR`
4. `ADD`: 如果$rs2=x0$, 则`ADD -> EBREAK`
5. `JALR`: 如果$rs1==x0$, 则`JALR -> EBREAK`

## HINTs instruction

> HINTs 指令功能类似于 nop 指令，它除了增加 PC 或者其他 counter 之外不会对系统产生任何影响, 不用在微架构里实现 HINTs 指令

1. `NOP`和`ADDI`: $imm==0$
2. `LI`, `LUI`: $rd==x0$
3. `SLLI`, `SRLI`和`SRAI`: $rd==x0$ 或者$imm==0$
