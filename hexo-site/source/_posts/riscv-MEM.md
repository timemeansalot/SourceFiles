---
title: RISC-V 访存级
date: 2023-04-05 11:59:22
tags: RISC-V
---

![memory](https://s2.loli.net/2023/04/10/kOp5QAIJYuU6q91.png)
RISCV MEM Stage 设计

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

> MEM 和 EXE 需要 resetn 信号，否则系统 reset 之后，MEM Stage 输出的`reg_wb_en`会是 x，传输给 ID Stage 之后，会导致第一次读取 RF 时读出的也是 x

## MEM Stage Design for Load/Store instructions

> 由于 CSR 模块放到 MEM Stage 会导致流水线刷新逻辑涉及到更多一个 Stage，导致刷新逻辑变得复杂，
> 因此考虑将 CSR 模块放到 EXE Stage，并且在 EXE Stage 对访存指令地址不对齐的情况触发 exception

### 地址不对齐的情况

- [ ] TODO: should be put in EXE stage in CSR unit

1. LB, LBU, SB 指令由于其操作的是 1B 的数据，因此不会出现 address misaligned exception
2. LH, LHU, SH 指令，`addr[0]!=0`时，会出现 address misaligned exception
3. LW, SW 指令，`addr[1:0]!=00`时，会出现 address misaligned exception

### dmem_write_en

- [ ] TODO: memory with byte enable

1. dmem_write_en = 0;

| dmem_write_en | mem_type                                 |
| ------------- | ---------------------------------------- |
| 0             | MEM_LB, MEM_LBU, MEM_LH, MEM_LHU, MEM_LW |
| 1             | MEM_SB, MEM_SH, MEM_SW                   |

### Store

1. byte_en

`byte_en[3:0]`：用于描述 D-Memory 写入时，那些 Byte 被写入

| byte_en | mem_type        | addr[1:0] |
| ------- | --------------- | --------- |
| 0001    | MEM_SB, MEM_SBU | 00        |
| 0010    | MEM_SB, MEM_SBU | 01        |
| 0100    | MEM_SB, MEM_SBU | 10        |
| 1000    | MEM_SB, MEM_SBU | 11        |
| 0011    | MEM_SH, MEM_SHU | 0x        |
| 1100    | MEM_SH, MEM_SHU | 1x        |
| 1111    | MEM_SW          | xx        |

2.  DMEM_wr_data_o

`write_data[31:0]`是写入到 D-Memory 中的数据, `wr_data` 是 EXE Stage 输入的代写入到 D-Memory 的数据

| write_data                                | mem_type        | addr[1:0] |
| ----------------------------------------- | --------------- | --------- |
| { {24{1'b0}}, wr_data[7:0] };             | MEM_SB, MEM_SBU | 00        |
| { {16{1'b0}}, wr_data[7:0], { 8{1'b0}} }; | MEM_SB, MEM_SBU | 01        |
| { {8{1'b0}}, wr_data[7:0], {16{1'b0}} };  | MEM_SB, MEM_SBU | 10        |
| { wr_data[7:0], {24{1'b0}} };             | MEM_SB, MEM_SBU | 11        |
| { {16{1'b0}}, wr_data[15:0] };            | MEM_SH, MEM_SHU | 0x        |
| { wr_data[15:0], {16{1'b0}} };            | MEM_SH, MEM_SHU | 1x        |
| wr_data                                   | MEM_SW          | xx        |

### Load 指令
