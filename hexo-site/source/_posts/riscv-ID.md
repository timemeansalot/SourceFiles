---
title: RISCV 译码级设计
date: 2023-04-04 10:11:49
tags: RISCV
---

## RISCV ID Stage 各个功能部件设计

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

      | $opcode_{[6:2]}$ | Instruction Type | Instruction Amount | Relative Instructions                                |
      | ---------------- | ---------------- | ------------------ | ---------------------------------------------------- |
      | 01101            | U-Type           | 1                  | LUI                                                  |
      | 00101            | U-Type           | 1                  | AUIPC                                                |
      | 01000            | S-Type           | 3                  | SB, SH, SW                                           |
      | 00000            | I-Type           | 5                  | LB, BH, LW, LBU, LHU                                 |
      | 00100            | I-Type           | 9                  | ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI |
      | 01100            | R-Type           | 10                 | ADD, SUB, SLL, SLTU, XOR, OR, AND, SLL, SRL, SRA     |
      | 11001            | R-Type           | 1                  | JALR                                                 |
      | 11011            | J-Type           | 1                  | JAL                                                  |
      | 11000            | B-Type           | 6                  | BEQ, BNE, BLT, BGE, BLTU, BGEU                       |
      | 01100            | RV-M             | 8                  | MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU       |

   2. 由指令类型得到 immType, branchType, aluOp, dMemType, dMemWriteEn, regWBEn, regWBSrc

      - immType:

        | immType | Amount | Instruction opcode  |
        | ------- | ------ | ------------------- |
        | IMM_U   | 2      | 01101, 00101        |
        | IMM_J   | 1      | 11011               |
        | IMM_I   | 15     | 00100, 00000, 11001 |
        | IMM_B   | 6      | 11000               |
        | IMM_S   | 3      | 01000               |
        | IMM_NO  | 18     | 11000, 01100        |

      - dMemType, dMemWriteEn

        | Instructions opcode | funct3                              | dMemType                                             | dMemWriteEn |
        | ------------------- | ----------------------------------- | ---------------------------------------------------- | ----------- |
        | 01000               | 000<br/>001<br/>010                 | MEM_SB<br/>MEM_SH<br/>MEM_SW                         | 1           |
        | 00000               | 000<br/>001<br/>010<br/>100<br/>101 | MEM_LH<br/>MEM_LB<br/>MEM_LW<br/>MEM_LBU<br/>MEM_LHU | 0           |
        | others              | xxx                                 | MEM_NO                                               | 0           |

      - regWBEn

        | regWBEn | Amount | Instruction opcode |
        | ------- | ------ | ------------------ |
        | 0       | 9      | 01000, 11000       |
        | 1       | 36     | others             |

      - regWBSrc

        | regWBSrc           | Amount | Instruction opcode |
        | ------------------ | ------ | ------------------ |
        | WBSrc_aluResult    | 37     | others             |
        | WBSrc_dMemReadData | 5      | 00000              |
        | WBSrc_extendedImm  | 1      | 01101              |
        | WBSrc_pcPlus4      | 2      | 11001, 11011       |

      - TODO: branchType, aluOp

   3. 根据 instruction 得到 rs1, rs2 和 rd: `rs2=instr[24:20], rs1=[19:15], rd=instr[11:7]`

### 静态分支预测 SBP(Static Branch Predictor)

1. 输入接口

   | Name            | Source         | Description                                                                               |
   | --------------- | -------------- | ----------------------------------------------------------------------------------------- |
   | PC[31:0]        | IF/ID pipeline | 用于计算重定向 PC                                                                         |
   | RD1[31:0]       | 4x1 Mux        | 用于计算重定向 PC                                                                         |
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
      - JALR: `RPC=(RD1+offset) & 0xfffffffe`

      calculation 部分需要一个加法器用于计算 RPC，加法器的一个输入恒为 offset; 另一个输入为 PC 或者是 RD1, RD1 如果存在数据依赖，需要从后面的流水线 bypass(此处复用了 ID 级本身的 bypass 逻辑，即复用了 ID 的四选一 mux)

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
   | RD1  | 4x1 Mux | 从 RF 中读出的操作数 1 |
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

   1. IMM_U: `imm={instr[31:12], 12'h000}`
   2. IMM_J: `imm={11{instr[31]}, instr[31], instr[19:15], instr[20], instr[30:21], 1'b0}`
   3. IMM_I: `imm={20{instr[31]}, instr[31:20]}`
   4. IMM_B: `imm={19{instr[31]}, instr[31], instr[7], instr[30,25], instr[11,8]}`
   5. IMM_S: `imm={20{instr[31]}, instr[31:25], instr[11:7]}`
   6. IMM_NO: no immediate

### 4x1 Mux

1. 输入接口

   | Name            | Source    | Description                    |
   | --------------- | --------- | ------------------------------ |
   | RD1[31:0]       | RF        | 从 RF 读出的操作数 1           |
   | RD2[31:0]       | RF        | 从 RF 读出的操作数 2           |
   | exeBypass[31:0] | EXE stage | data forwarding from EXE stage |
   | memBypass[31:0] | MEM stage | data forwarding from MEM stage |
   | wbBypass[31:0]  | WB stage  | data forwarding from WB stage  |

   TODO: 确定一下 forwarding 的来源

2. 输出接口

   | Name       | Target          | Description           |
   | ---------- | --------------- | --------------------- |
   | RD1D[31:0] | ID/EXE pipeline | 送给 ALU 的 operand 1 |
   | RD2D[31:0] | ID/EXE pipeline | 送给 ALU 的 operand 2 |

3. 模块功能

TODO: 补充到 hazard unit 的 wire 连接
