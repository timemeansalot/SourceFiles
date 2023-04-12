---
title: RISC-V压缩指令集
date: 2023-04-10 19:58:24
tags: RISCV
---

![RV-32C](https://s2.loli.net/2023/04/10/C73opKyZbMJrktW.png)
RISC-V 压缩指令集学习笔记

<!--more-->

Total RVC instructions:

1. Load and Store(4): `LW`, `SW`, `LWSP`, `SWSP`
2. Control(4): `J`, `JAL`, `JR`, `JALR`
3. Integer:
   - Register-Immediate(9): `LI`, `LUI`, `ADDI`, `ADDI16SP`, `ADDI16SPN`, `SLLI`, `SRLI`, `SRAI`, `ANDI`
   - Register-Register(6): `MV`, `AND`, `OR`, `XOR`, `SUB`, `ADD`
   - Others(3): `NOP`, `EBREAK`, `HINT`

RV-32IM 中不存在压缩指令的指令：

| $opcode_{[6:2]}$ | Instruction Type | Relative Instructions                          |
| ---------------- | ---------------- | ---------------------------------------------- |
| 00101            | U-Type           | AUIPC                                          |
| 01000            | S-Type           | SB, SH                                         |
| 00000            | I-Type           | LB, BH, LBU, LHU                               |
| 00100            | I-Type           | SLTI, SLTIU, XORI, ORI                        |
| 01100            | R-Type           | SLT, SLTU, SLLI, SRLI, SRAI                    |
| 11000            | B-Type           | BLT, BGE, BLTU, BGEU                           |
| 01100            | RV-M             | MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU |

## RV-32C

> Typically, 50%–60% of the RISC-V instructions in a program can be replaced with RVC instructions, resulting in a 25%–30% code-size reduction.

1. 什么时候可以压缩
   1. imm, offset 很小的时候
   2. register 是 x0, x1 或者 x2
   3. register 是常用的那 8 个
   4. rs1=rd
2. RV-32C 可以跟其他指令集搭配使用，不能单独使用；启用 RV-32C 之后，32bits 的指令和 16bits 的指令是混合存放的，并且此时不会有 `instruction-address-misaligned exceptions`
3. RV-32C 可以在 ID 的时候很容易地被恢复成 RV-32I

## RV-32C 编码

![RVC formats](https://s2.loli.net/2023/04/11/snKwlv6QH1yPWxJ.png)

1. frequently used registers：x8~x15，其 3bits 编码从 000 到 111
2. rs1, rs2 放在 RVC 固定的字段、rd 在 RVC 中的字段是不固定的
3. 在 RVC 中，imm 不可以被赋值为 0，0 不是合法的 register index(x0 不会在 RVC 字段中出现)
4. CR, CI, CSS 格式的指令可以使用所有的 32 个 register，因为其 register 由 5bits 指定；其余格式的指令只可以使用 x8~x15 这 8 个 register，因为其 register 由 3bits 指定

### Stack-Pointer Based Loads and Stores

SP 默认使用 x2 作为基地址来和 offset 相加得到访问 Data-Memory 的地址

#### C.LWSP(Load Word Stack Pointer)

1. 是 `CI` 格式的指令
2. C.LWSP loads a 32-bit value from memory into register rd.
3. It computes an effective address by adding the <u>zero-extended offset, scaled by 4</u>, to the stack pointer, x2.
4. It expands to `lw rd, offset[7:2](x2)`
5. 要求$rd\neq0$

C.LWSP 指令格式：

| 15-13  | 12         | 11-7 | 6-2               | 1-0    |
| ------ | ---------- | ---- | ----------------- | ------ |
| funct3 | imm        | rd   | imm               | opcode |
| 010    | uOffset[5] | rd   | uOffset[4:2\|7:6] | 10     |

> PS: uOffset for unsigned_offset

LW 的指令格式：

| 31-20        | 19-15 | 14-12  | 11-7 | 6-0     |
| ------------ | ----- | ------ | ---- | ------- |
| imm          | rs1   | funct3 | rd   | opcode  |
| offset[11:0] | rs1   | 010    | rd   | 0000011 |

令 LW 指令为 I，C.LWSP 指令为 C，则由 C 扩展为 I 的过程如下：

1. 恢复 opcode

   ```verilog
   I[6:0]=I_opcode=7'b0000011
   ```

2. 恢复 funct3
   ```verilog
   C_funct3=C[15:13]
   I_funct3=C_funct3
   I[14:12]=I_funct3
   ```
3. 恢复 rd
   ```verilog
   C_rd=C[11:7]
   I_rd=C_rd
   I[11:7]=I_rd
   ```
4. 恢复 rs1
   ```verilog
   I_rs1=x2=5'b00010
   I[14:12]=I_rs1
   ```
5. <u>恢复 offset</u>

   ```verilog
   C_offset={C[3:2], C[12], C[6:5]}
   I_offset={4'b0000, C_offset, 2'b00} // scaled by 4, zero-extended
   I[31:20]=I_offset
   ```

#### C.SWSP(Store Word Stack Pointer)

1. 是 `CSS` 格式的指令
2. stores a 32-bit value in register rs2 to memory.
3. It computes an effective address by adding the <u>zero-extended offset, scaled by 4</u>, to the stack pointer, x2.
4. It expands to `sw rs2, offset[7:2](x2)`

C.SWSP 指令格式：

| 15-13  | 12-7              | 6-2 | 1-0    |
| ------ | ----------------- | --- | ------ |
| funct3 | imm               | rs2 | opcode |
| 110    | uOffset[5:2\|7:6] | src | 10     |

SW 指令格式：

| 31-25        | 24-20 | 19-15 | 14-12  | 11-7        | 6-0     |
| ------------ | ----- | ----- | ------ | ----------- | ------- |
| imm          | src   | base  | funct3 | imm         | opcode  |
| offset[11:5] | rs2   | rs1   | 010    | offset[4:0] | 0100011 |

令 SW 指令为 I，C.SWSP 指令为 C，则由 C 扩展为 I 的过程如下：

1. 恢复 opcode

   ```verilog
   I[6:0]=I_opcode=7'b0100011
   ```

2. 恢复 funct3
   ```verilog
   I_funct3=3'b010
   I[14:12]=I_funct3
   ```
3. 恢复 rs2
   ```verilog
   C_rs2=C[6:2]
   I_rs2=C_rs2
   I[24:20]=I_rs2
   ```
4. 恢复 rs1
   ```verilog
   I_rs1=x2=5'b00010
   I[14:12]=I_rs1
   ```
5. <u>恢复 offset</u>

   ```verilog
   C_offset={C[8:7], C[12:9]}
   I_offset={4'b0000, C_offset, 2'b00} // scaled by 4, zero-extended
   {I[31:25], I[11:7]}=I_offset
   ```

### Register-Based Loads and Stores

rs1 不再是默认为 x2，而是由 3bits 的 rs1'来指定，可以选择 x8~x15 中的任一个；同时 rd 也由 5bits 缩短为 3bits 的 rd'

#### C.LW

1. 是`CW`格式
2. loads a 32-bit value from memory into register rd′.
3. It computes an effective address by adding the <u>zero-extended offset, scaled by 4</u>, to the base address in register rs1′.
4. It expands to `lw rd′, offset[6:2](rs1′)`.

C.LW 指令格式

| 15-13  | 12-10        | 9-7  | 6-5           | 4-2  | 1-0    |
| ------ | ------------ | ---- | ------------- | ---- | ------ |
| funct3 | imm          | rs1' | imm           | rd'  | opcode |
| 010    | uOffset[5:3] | base | uOffset[2\|6] | dest | 00     |

LW 的指令格式：

| 31-20        | 19-15 | 14-12  | 11-7 | 6-0     |
| ------------ | ----- | ------ | ---- | ------- |
| imm          | rs1   | funct3 | rd   | opcode  |
| offset[11:0] | rs1   | 010    | rd   | 0000011 |

令 LW 指令为 I，C.LW 指令为 C，则由 C 扩展为 I 的过程如下：

1. 恢复 opcode

   ```verilog
   I[6:0]=I_opcode=7'b0000011
   ```

2. 恢复 funct3
   ```verilog
   C_funct3=C[15:13]
   I_funct3=C_funct3
   I[14:12]=I_funct3
   ```
3. 恢复 rd
   ```verilog
   C_rd=C[4:2]
   I_rd={2'b01, C_rd}
   I[11:7]=I_rd
   ```
4. 恢复 rs1
   ```verilog
   C_rs1=C[9:7]
   I_rs1={2'b01, C_rs1}
   I[14:12]=I_rs1
   ```
5. <u>恢复 offset</u>

   ```verilog
   C_offset={C[5], C[12:10], C[6]}
   I_offset={5'b00000, C_offset, 2'b00} // scaled by 4, zero-extended, imm in CL only 5 bits
   I[31:20]=I_offset
   ```

#### C.SW

1. 是`CS`格式
2. stores a 32-bit value in register rs2′ to memory.
3. It computes an effective address by adding the <u>zero-extended offset, scaled by 4</u>, to the base address in register rs1′.
4. It expands to `sw rs2′, offset[6:2](rs1′)`

C.SW 指令格式

| 15-13  | 12-10        | 9-7  | 6-5           | 4-2  | 1-0    |
| ------ | ------------ | ---- | ------------- | ---- | ------ |
| funct3 | imm          | rs1' | imm           | rs2' | opcode |
| 110    | uOffset[5:3] | base | uOffset[2\|6] | src  | 00     |

> PS: C.SW 和 C.LW 的区别在于
>
> 1. 其[4:2]字段由 rd'变成了 rs2'
> 2. 其[15]字段由 0 变成了 1

SW 的指令格式：

| 31-25        | 24-20 | 19-15 | 14-12  | 11-7        | 6-0     |
| ------------ | ----- | ----- | ------ | ----------- | ------- |
| imm          | src   | base  | funct3 | imm         | opcode  |
| offset[11:5] | rs2   | rs1   | 010    | offset[4:0] | 0100011 |

令 SW 指令为 I，C.SW 指令为 C，则由 C 扩展为 I 的过程如下：

1. 恢复 opcode

   ```verilog
   I[6:0]=I_opcode=7'b0100011
   ```

2. 恢复 funct3
   ```verilog
   I_funct3=3'b010
   I[14:12]=I_funct3
   ```
3. 恢复 rs2
   ```verilog
   C_rs2=C[4:2]
   I_rs2={2'b01, C_rs2}
   I[24:20]=I_rs2
   ```
4. 恢复 rs1
   ```verilog
   C_rs1=C[9:7]
   I_rs1={2'b01, C_rs1}
   I[14:12]=I_rs1
   ```
5. <u>恢复 offset</u>

   ```verilog
   C_offset={C[5], C[12:10], C[6]}
   I_offset={5'b00000, C_offset, 2'b00} // scaled by 4, zero-extended, imm in CS only 5 bits
   {I[31:25], I[11:7]}=I_offset
   ```

6. `I[ 6: 0]=7b'0100011`
7. `I[11: 7]={C[11:10], C[6], 2{1'b0}}`
8. `I[14:12]=3'b010`
9. `I[19:15]={2'b01, C[9:7]}`
10. `I[24:20]={2'b01, C[4:2]}`
11. `I[31:25]={5{1'b0},C[12], C[5]}`

> PS: C.LW 和 C.SW 的 imm 都只有 5bits，C.LWSP 和 C.SWSP 的 imm 都有 6bits

### Control Transfer instructions

1. C.J 和 C.JAL 都是`CJ`格式的指令
2. The offset is <u>sign-extended and added to the pc</u> to form the jump target address

其中：

1. C.J 扩展为`jal x0, offset[11:1]`, funct3=101
2. C.JAL 扩展为: `jal x1, offset[11:1]`, funct3=001

C.J 和 C.JAL 指令格式：

| 15-13  | 12-2                                | 1-0    |
| ------ | ----------------------------------- | ------ |
| funct3 | imm                                 | opcode |
| 101    | offset[11\|4\|9:8\|10\|6\|7\|3:1\|5 | 01     |
| 001    | offset[11\|4\|9:8\|10\|6\|7\|3:1\|5 | 01     |

JAL 指令格式为：

| 31-20            | 19-12      | 11-7 | 6-0     |
| ---------------- | ---------- | ---- | ------- |
| imm[20\|10:1\|11 | imm[19:12] | rd   | 1101111 |

令 JAL 指令为 I，C.J 或者 C.JAL 指令为 C，则由 C 扩展为 I 的过程如下：
