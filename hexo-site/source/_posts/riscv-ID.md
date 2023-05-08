---
title: RISC-V 译码级设计
date: 2023-04-04 10:11:49
tags: RISC-V
---

![Decode](https://s2.loli.net/2023/04/10/cMZH3xzBy5aDSeK.png)
RISC-V 译码级设计

<!--more-->

## RISCV ID Stage 各个功能部件设计

![pipeline_ID](/Users/fujie/Pictures/typora/pipeline/pipeline_ID.svg)

### 压缩指令译码(compress decoder)

用于将压缩指令恢复成 32 bits 的正常指令，再送往 decoder 进行译码，压缩指令详细说明见[压缩指令](https://timemeansalot.github.io/2023/04/10/RISCV-compressISA/)

### 译码控制(Decoder)

1. 输入接口

   | Name              | Source | Description  |
   | ----------------- | ------ | ------------ |
   | instruction[31:0] | IR     | 待译码的指令 |

2. 输出接口

   | Name            | Target               | Description                                 |
   | --------------- | -------------------- | ------------------------------------------- |
   | immType[2:0]    | EU                   | 立即数类型                                  |
   | rs1[4:0]        | RF                   | register source1 index                      |
   | rs2[4:0]        | RF                   | register source2 index                      |
   | branchType[2:0] | SBP, ID/EXE pipeline | 分支类型                                    |
   | rd[4:0]         | ID/EXE pipeline      | register destination index                  |
   | aluOp[4:0]      | ID/EXE pipeline      | ALU 执行的操作                              |
   | dMemWriteEn     | ID/EXE pipeline      | ALU 执行的操作                              |
   | dMemType[3:0]   | ID/EXE pipeline      | ALU 执行的操作                              |
   | regWBEn         | ID/EXE pipeline      | 写使能                                      |
   | regWBSrc[1:0]   | ID/EXE pipeline      | 一直传递到 WB stage，用于选择写回的数据来源 |

3. 模块功能

   Decoder 对输入的指令进行译码，生成流水线上其它模块的控制信号

   1. 根据 instruction 的 opcode, funct3 和 funct7 得到指令的类型：opcode -> funct3 -> funct7

      - `opcode=instr[6:2], funct3=instr[14:12], funct7=instr[30]`

      > opcode 一共 7bits，其中低 2bits 恒为 11，只有高 5bits 不同

      | $opcode_{[6:0]}$ | Instruction Opcode Type | Instruction Amount | Relative Instructions                                                                            |
      | ---------------- | ----------------------- | ------------------ | ------------------------------------------------------------------------------------------------ |
      | 0000011          | OPCODE_LOAD             | 5                  | LB, BH, LW, LBU, LHU                                                                             |
      | 0010011          | OPCODE_OP_IMM           | 9                  | ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI                                             |
      | 0010111          | OPCODE_AUIPC            | 1                  | AUIPC                                                                                            |
      | 0100011          | OPCODE_STORE            | 3                  | SB, SH, SW                                                                                       |
      | 0110011          | OPCODE_RTYPE            | 18                 | ADD, SUB, SLT, SLTU, XOR, OR, AND, SLL, SRL, SRA, MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU |
      | 0110111          | OPCODE_LUI              | 1                  | LUI                                                                                              |
      | 1100011          | OPCODE_BRANCH           | 6                  | BEQ, BNE, BLT, BGE, BLTU, BGEU                                                                   |
      | 1100111          | OPCODE_JALR             | 1                  | JALR                                                                                             |
      | 1101111          | OPCODE_JAL              | 1                  | JAL                                                                                              |

   2. 由指令类型得到 immType, branchType, aluOp, dMemType, dMemWriteEn, regWBEn, regWBSrc

      1. immType:

         | immType | Amount | Instruction opcode                      |
         | ------- | ------ | --------------------------------------- |
         | IMM_U   | 2      | OPCODE_LUI, OPCODE_AUIPC                |
         | IMM_J   | 1      | OPCODE_JAL                              |
         | IMM_I   | 15     | OPCODE_OP_IMM, OPCODE_LOAD, OPCODE_JALR |
         | IMM_B   | 6      | OPCODE_BRANCH                           |
         | IMM_S   | 3      | OPCODE_STORE                            |
         | IMM_NO  | 18     | OPCODE_RTYPE                            |

      2. dMemType, dMemWriteEn

         | Instructions opcode | funct3                              | dMemType                                             | dMemWriteEn |
         | ------------------- | ----------------------------------- | ---------------------------------------------------- | ----------- |
         | 01000               | 000<br/>001<br/>010                 | MEM_SB<br/>MEM_SH<br/>MEM_SW                         | 1           |
         | 00000               | 000<br/>001<br/>010<br/>100<br/>101 | MEM_LH<br/>MEM_LB<br/>MEM_LW<br/>MEM_LBU<br/>MEM_LHU | 0           |
         | others              | xxx                                 | MEM_NO                                               | 0           |

      3. regWBEn

         | regWBEn | Amount | Instruction opcode |
         | ------- | ------ | ------------------ |
         | 0       | 9      | 01000, 11000       |
         | 1       | 36     | others             |

      4. regWBSrc

         | regWBSrc           | Amount | Instruction opcode |
         | ------------------ | ------ | ------------------ |
         | WBSrc_aluResult    | 37     | others             |
         | WBSrc_dMemReadData | 5      | 00000              |
         | WBSrc_extendedImm  | 1      | 01101              |
         | WBSrc_pcPlus4      | 2      | 11001, 11011       |

      5. branchType

         - branchBType: OPCODE_BRANCH
         - branchJAL: OPCODE_JAL
         - branchJALR: OPCODE_JALR

      6. aluOp

         | Instruction Opcode Type                             | funct3(funct7)                                                                          | Relative Instructions                                                        | aluOp                                                                                                                                            |
         | --------------------------------------------------- | --------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
         | OPCODE_LOAD                                         | 000<br />001<br /><br />010<br />100<br />101                                           | LB<br />BH<br />LW<br />LBU<br />LHU                                         | ALUOP_ADD                                                                                                                                        |
         | OPCODE_OP_IMM                                       | 000<br />010<br />011<br />100<br />110<br />111<br />001<br />101(0)<br />101(1)       | ADDI<br/>SLTI<br/>SLTIU<br/>XORI<br/>ORI<br/>ANDI<br/>SLLI<br/>SRLI<br/>SRAI | ALUOP_ADD<br />ALUOP_SLT<br />ALUOP_SLTU<br />ALUOP_XOR<br />ALUOP_OR<br />ALUOP_AND<br />ALUOP_SLL<br />ALUOP_SRL<br />ALUOP_SRA                |
         | OPCODE_AUIPC<br/>`rs1=pc`                           |                                                                                         | AUIPC                                                                        | ALUOP_ADD                                                                                                                                        |
         | OPCODE_STORE                                        | 000<br/>001<br/>010                                                                     | SB<br/>SH<br/>SW                                                             | ALUOP_ADD                                                                                                                                        |
         | OPCODE_RTYPE(instr[25]==0)<br/> `rd2=register file` | 000(0)<br/>000(1)<br/>001<br/>010<br/>011<br/>100<br/>101(0)<br/>101(1)<br/>110<br/>111 | ADD<br/>SUB<br/>SLL<br/>SLT<br/>SLTU<br/>XOR<br/>SRL<br/>SRA<br/>OR<br/>AND  | ALUOP_ADD<br />ALUOP_SUB<br />ALUOP_SLL<br />ALUOP_SLT<br />ALUOP_SLTU<br />ALUOP_XOR<br />ALUOP_SRL<br />ALUOP_SRA<br />ALUOP_OR<br />ALUOP_AND |
         | OPCODE_RTYPE(instr[25]==1)<br/> `rd2=register file` | 000<br/>001<br/>010<br/>011<br/>100<br/>101<br/>110<br/>111                             | MUL<br/>MULH<br/>MULHSU<br/>MULHU<br/>DIV<br/>DIVU<br/>REM<br/>REMU          | ALUOP_MUL<br/>ALUOP_MULH<br/>ALUOP_MULHSU<br/>ALUOP_MULHU<br/>ALUOP_DIV<br/>ALUOP_DIVU<br/>ALUOP_REM<br/>ALUOP_REMU                              |
         | OPCODE_LUI                                          |                                                                                         | LUI                                                                          | ALUOP_ADD                                                                                                                                        |
         | OPCODE_BRANCH<br/>`rs1=pc`                          | 000<br/>001<br/>100<br/>101<br/>110<br/>111                                             | BEQ<br/>BNE<br/>BLT<br/>BGE<br/>BLTU<br/>BGEU                                | ALUOP_SUB<br />ALUOP_SUB<br />ALUOP_SLT<br />ALUOP_SLT<br />ALUOP_SLTU<br />ALUOP_SLTU                                                           |
         | OPCODE_JALR                                         |                                                                                         | JALR                                                                         | ALUOP_ADD                                                                                                                                        |
         | OPCODE_JAL<br/>`rs1=pc`                             |                                                                                         | JAL                                                                          | ALUOP_ADD                                                                                                                                        |

   3. 根据 instruction 得到 rs1, rs2 和 rd: `rs2=instr[24:20], rs1=[19:15], rd=instr[11:7]`

### 静态分支预测 SBP(Static Branch Predictor)

1. 输入接口

   | Name            | Source         | Description                                                                               |
   | --------------- | -------------- | ----------------------------------------------------------------------------------------- |
   | PC[31:0]        | IF/ID pipeline | 用于计算重定向 PC                                                                         |
   | rs1[31:0]       | 4x1 Mux        | 用于计算重定向 PC                                                                         |
   | offset[31:0]    | EU             | 用于计算重定向 PC                                                                         |
   | branchType[2:0] | Decoder        | `branchType[0]==1 -> JAL`<br/>`branchType[1]==1 -> JALR`<br/>`branchType[2]==1 -> B-Type` |

2. 输出接口

   | Name      | Target                    | Description                                                      |
   | --------- | ------------------------- | ---------------------------------------------------------------- |
   | RPC[31:0] | IF Stage                  | Redirection PC                                                   |
   | taken     | IF Stage, ID/EXE pipeline | 预测跳转是否发生, ALU 会计算实际跳转是否发生并且与此预测结果比较 |

3. 模块功能

   若 decoder 译码之后判断指令是分支指令，则 SBP 需要根据静态分支预测的规则，生成重定向 PC，发送给 IF 级。SBP 具体做了如下两个任务：

   1. 判断是否需要跳转 prediction
      - JAL, JALR: `taken=1`
      - B-TYpe: forward not taken, backward taken, 根据 offset 正负号来判断, `taken=offset[31]`
   2. 计算跳转的方向 calculation

      - JAL, B-Type: `RPC=PC+offset`
      - JALR: `RPC=(rs1+offset) & 0xfffffffe`

   3. ** 在计算 JARL 指令的新的 pc 地址的时候，需要访问寄存器，但是寄存器的值可能会跟前面的指令存在数据依赖，此时有两种方法**来解决：
      - 利用 bypass 来结局数据依赖问题之后，再在 SBP 中计算目的 pc，该方法可能会导致 ID 关键路径太长
      - 仅在 rs1=x0, x1 的时候计算 JALR 的目的 pc，其余情况下若存在数据依赖，则预判 JALR 不跳转，在 EXE 中计算正确的目的 pc

   > 前者 JALR 指令预测准确率 100%，但是 ID 级关键路径长；后者 JALR 指令预测率稍低但是 ID 关键路径短

### RF(Register File)

1. 输入接口

   | Name            | Source      | Description                |
   | --------------- | ----------- | -------------------------- |
   | rs1[4:0]        | Decoder     | register source1 index     |
   | rs2[4:0]        | Decoder     | register source2 index     |
   | rd[4:0]         | WB pipeline | register destination index |
   | regWBData[31:0] | WB pipeline | 待写回到 RF 的数据         |
   | regWBEn         | WB pipeline | 写使能                     |

2. 输出接口

   | Name | Target  | Description            |
   | ---- | ------- | ---------------------- |
   | rs1  | 4x1 Mux | 从 RF 中读出的操作数 1 |
   | RD2  | 4x1 Mux | 从 RF 中读出的操作数 2 |

3. 模块功能

   RF 支持在任意时刻读出数据，它有两个读端口，一个写端口（写数据的时候必须在 clk 上升沿且写使能）

### 立即数扩展单元 EU(Extending Unit)

1. 输入接口

   | Name              | Source         | Description            |
   | ----------------- | -------------- | ---------------------- |
   | instruction[31:0] | IF/ID pipeline | 取值得到的 32bits 指令 |
   | immType[2:0]      | Decoder        | 立即数种类｜           |

2. 输出接口

   | Name      | Target               | Description                              |
   | --------- | -------------------- | ---------------------------------------- |
   | imm[31:0] | SBP, ID/EXE pipeline | 32bits 的立即数，送给 SBP 和下一级流水线 |

3. 模块功能

   该模块是纯组合电路，其根据输入的 immType 字段从 instruction 中摘取对应字段生成 32bits 的扩展立即数

   1. IMM_U: `imm_o={instr_i[31:12], 12'h000};`
   2. IMM_J: `imm_o={{11{instr_i[31]}}, instr_i[31], instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};`
   3. IMM_I: `imm_o={{20{instr_i[31]}}, instr_i[31:20]};`
   4. IMM_B: `imm_o={{19{instr_i[31]}}, instr_i[31], instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};`
   5. IMM_S: `imm_o={{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};`
   6. IMM_NO: no immediate ==> `imm_o = 32'h00000000;`

~~### 4x1 Mux~~
~~1. 输入接口~~

```
~~   | Name            | Source    | Description                    |~~
~~   | --------------- | --------- | ------------------------------ |~~
~~   | rs1[31:0]       | RF        | 从 RF 读出的操作数 1           |~~
~~   | RD2[31:0]       | RF        | 从 RF 读出的操作数 2           |~~
~~   | exeBypass[31:0] | EXE stage | data forwarding from EXE stage |~~
~~   | memBypass[31:0] | MEM stage | data forwarding from MEM stage |~~
~~   | wbBypass[31:0]  | WB stage  | data forwarding from WB stage  |~~
~~2. 输出接口~~
~~   | Name       | Target          | Description           |~~
~~   | ---------- | --------------- | --------------------- |~~
~~   | rs1D[31:0] | ID/EXE pipeline | 送给 ALU 的 operand 1 |~~
~~   | RD2D[31:0] | ID/EXE pipeline | 送给 ALU 的 operand 2 |~~
~~3. 模块功能: 根据 forwarding 选择信号，选择合适的 forward 数据，将选择的数据输送到 EXE Stage~~
```
