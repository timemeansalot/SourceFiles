---
title: RISCV 访存级
date: 2023-04-05 11:59:22
tags: RISCV
---

## RISCV MEM Stage 设计

<!--more-->

### Data Memory(DM)

> DM 采用 DTCM，其访问的数据类型必须按照对应的地址对齐，否则就是 misaligned data address。例如 LW，SW，其地址最低两位必须是 00.

1. 输入端口

   | Port Name       | Source           | Description             |
   | --------------- | ---------------- | ----------------------- |
   | addr[DMEMLEN:0] | aluResult        | dMemory 输入地址        |
   | dMemInput[31:0] | DMIC             | 寄存器 rs2 读出的数据   |
   | dMemWrEn        | EXE/MEM pipeline | dMemory 写入使能        |
   | byteMask[3:0]   | DMIC             | dMemory byteMask        |
   | mvalid          | DMIC             | DMIC 输入数据有效       |
   | mready          | DMOC             | DMOC 空闲，可以输出数据 |

2. 输出端口

   | Port Name        | Target | Description                |
   | ---------------- | ------ | -------------------------- |
   | dMemOutput[31:0] | DMOC   | 输出到 WB stage 的 Mux     |
   | svalid           | DMOC   | MEM 数据有效               |
   | sready           | DMIC   | MEM 空闲，可以进行读写操作 |

### Data Memory Input Control(DMIC)

根据指令的格式，生成输入到 Data Memory 的 32bits 数据

1. 输入端口

   | Port Name       | Source           | Description                   |
   | --------------- | ---------------- | ----------------------------- |
   | dMemType[3:0]   | EXE/MEM pipeline | 访存指令的格式                |
   | RD2[31:0]       | EXE/MEM pipeline | 寄存器 rs2 读出的数据         |
   | aluResult[31:0] | EXE ALU          | alu 计算得到的 dMemory 地址｜ |
   | ready           | DM               | Dta Memory 空闲               |

   `byte_addr=aluResult[1:0]`

2. 输出端口

   | Port Name       | Target | description                                |
   | --------------- | ------ | ------------------------------------------ |
   | dMemInput[31:0] | DM     | 根据 dmemtype 生成的 32bitsdata，输出到 DM |
   | byteMask[3:0]   | DM     | dMemory write byteMask                     |

   `byteMask=aluResult[1:0]`

   | dMemType | byte_addr                    | dMemInput                                                                                                                                                              |
   | -------- | ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
   | MEM_LB   | 00<br/>01<br/>10<br/>11<br/> | `dMemInput={24{1'b0},RD2[7:0]}`<br/>`dMemInput={16{1'b0},RD2[15:8],8{1'b0}}`<br/>`dMemInput={8{1'b0},RD2[23:16],16{1'b0}}`<br/>`dMemInput={RD2[31:24], 24{1'b0}}`<br/> |
   | MEM_LH   | 00<br/>10                    | `dMemInput={16{1'b0},RD2[15:0]}`<br/>`dMemInput={RD2[31:16], 16{1'b0}}`                                                                                                |
   | MEM_LW   |                              | `dMemInput=RD2[31:0]`                                                                                                                                                  |

### Data Memory Output Control(DMOC)

接收 DM 的输出数据，并且根据指令格式产生对应的数据，输入给 WB Stage

1. 输入端口

   | Port Name        | Source           | Description                   |
   | ---------------- | ---------------- | ----------------------------- |
   | dMemType[3:0]    | EXE/MEM pipeline | 访存指令的格式                |
   | dMemOutput[31:0] | DM               | 从 DM 中读入的 32bits 数据    |
   | aluResult[31:0]  | EXE ALU          | alu 计算得到的 dMemory 地址｜ |

2. 输出端口

   | Port Name          | Target   | Description                                              |
   | ------------------ | -------- | -------------------------------------------------------- |
   | dMemReadData[31:0] | WB stage | 根据 dMemType 选择 DM 输入的数据，生成 32bits 的读出数据 |

   | dMemType | byte_addr                    | dMemReadData                                                                                                                                                                                                                           |
   | -------- | ---------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
   | MEM_LB   | 00<br/>01<br/>10<br/>11<br/> | `dMemReadData={24{dMemOutput[7]}, dMemOutput[7:0]}`<br/> `dMemReadData={24{dMemOutput[15]}, dMemOutput[15:8]}`<br/> `dMemReadData={24{dMemOutput[23]}, dMemOutput[23:16]}`<br/> `dMemReadData={24{dMemOutput[31]}, dMemOutput[31:24]}` |
   | MEM_LH   | 00<br/>10                    | `dMemReadData={16{dMemOutput[15]}, dMemOutput[15:0]}`<br/>`dMemReadData={16{dMemOutput[31]}, dMemOutput[31:16]}`                                                                                                                       |
   | MEM_LW   |                              | `dMemReadData=dMemOutput[31:0]`                                                                                                                                                                                                        |
   | MEM_LBU  | 00<br/>01<br/>10<br/>11<br/> | `dMemReadData={24{1'b0}, dMemOutput[7:0]}`<br/> `dMemReadData={24{1'b0}, dMemOutput[15:8]}`<br/> `dMemReadData={24{1'b0}, dMemOutput[23:16]}`<br/> `dMemReadData={24{1'b0}, dMemOutput[31:24]}`                                        |
   | MEM_LHU  | 00<br/>10                    | `dMemReadData={16{1b'0}, dMemOutput[15:0]}`<br/>`dMemReadData={16{1'b0}, dMemOutput[31:16]}`                                                                                                                                           |

### Control Status Register Unit(CSRU)

TBD
