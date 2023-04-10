---
title: 周报 2023-04-08
date: 2023-03-24 16:12:31
tags: RISCV
---

每周周报
<!--more-->
## 流水线取指部分设计

> 取指阶段主要需要解决的问题是：<u>PC 重定向、指令对齐</u>

### PC 重定向

1. IF 没有分支预测，PC+=2  
   <u>IF 阶段设置有一个 FIFO，最多存储 5\*16bits 的数据</u>，该 FIFO 的设置是因为我们不知道指令是 16bits 的还是 32bits 的。

   **重定向发生的时候，I-Mem 直接采用重定向的 PC 作为取值地址**，可以避免 1 个 cycle 的 penalty

2. ID 采用静态分支预测，如果解码判断是分支指令，会计算 target PC  
   不会冲刷流水线
   ![redirection_ID](/Users/fujie/Pictures/typora/IF/redirection_ID.svg)
3. EXE 的 ALU 会对条件分支指令的结果进行判断，如果 ID 判断错误，EXE 会产生重定向 PC  
   冲刷 1 条流水线
   ![redirection_EXE](/Users/fujie/Pictures/typora/IF/redirection_EXE.svg)
4. MEM 的 CSR 单元会判断 trap 是否发生，如果发生 EXE 也会产生重定向 PC  
   冲刷 2 条流水线
   ![redirection_MEM](/Users/fujie/Pictures/typora/IF/redirection_MEM.svg)

### 指令对齐

![pipeline_scratch](/Users/fujie/Pictures/typora/IF/pipeline_scratch.svg)

1. FIFO 工作原理

   - FIFO 每次从 I-memory 读取 2x16 的数据
   - FIFO 中数据少于等于 3 的时候，FIFO 会从 I-memory 中读取数据，避免 underflow
   - FIFO 中数据大于 3 的时候，FIFO 会停止从 I-memory 中读取数据，避免 overflow
   - 当 ID 发现指令是 32bits 的时候，FIFO 头部 2 条数据会被 POP，FIFO 数据量-2
   - 当 ID 发现指令是 16bits 的时候，FIFO 头部 1 条数据会被 POP，FIFO 数据量-1

2. 采用 2 bank SRAM 作为 I-Memory, 两个 bank 的 SRAM 都是 16bits 的位宽，配合 FIFO 可以处理 32bits 指令不对齐的情况, 其工作原理如下：

   - 顺序读取: 顺序读取的时候不存在 PC 重定向，FIFO 不需要刷新

     1. 连续读 16bits 的指令：每次消耗 FIFO 中 1 条数据，读入 2 条数据到 FIFO，FIFO 数据量会逐步增加，当大于等于 3 的时候，FIFO 就不会继续从 I-memory 读取数据了
     2. 连续读 32bits 的指令：每次消耗 FIFO 中 2 条数据，读入 2 条数据到 FIFO，FIFO 数据量会保持恒定，FIFO 会继续从 I-memory 读取数据了
     3. 混合读取 16bits 和 32bits 的数据：上述两种方式的混合

   - PC 重定定向: 当发生 PC 重定向之后，FIFO 中现存的所有数据都是无效的，需要被刷新，并且下一个周期从 I-memory 中读出的指令也是无效的指令，也需要被丢弃; 在第二个周期读出的指令是重定向 PC 对应的指令，会被 PUSH 到 FIFO 中

> PS: 在只支持 32bits 指令的处理器中，JALR 指令可能会计算得到的 PC 不是 4B 对齐的，但是在模拟器中测试该场景的时候，模拟器默认忽略了 PC 最低 2bits，导致不对齐的 PC 也可以从 I-memory 中读取指令，没有触发 exception.

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

## RISCV WB Stage 设计

<!--more-->

WB Stage 主要功能部件是一个 4 选 1 Mux，根据 regWBSrcM 做写回选择，其输出结果送回到 RF 的写入数据输入端口

### WB 输入

| Port Name         | Source             | Description                                                                                                                     |
| ----------------- | ------------------ | ------------------------------------------------------------------------------------------------------------------------------- |
| regWBEnM          | MEM/WB pipeline    | ID 级计算得到，由流水线传递的<u>写回使能</u>信号                                                                                |
| rdM[4:0]          | MEM/WB pipeline    | ID 级计算得到，由流水线传递的<u>写回寄存器</u>索引                                                                              |
| regWBSrcM[1:0]    | MEM/WB pipeline    | ID 级计算得到，由流水线传递的<u>写回数据选择</u>信号<br/>1. alu: 0x00<br/>2. D-mem: 0x01<br/>3. imm: 0x10<br>4. pc+4: 0x11<br/> |
| aluResultM[31:0]  | MEM/WB pipeline    | ALU 计算得到的结果，由流水线传递                                                                                                |
| memReadData[31:0] | Data-Memory output | 由 D-Memory 读出，由于 D-Memory 本身有 1 个 cycle 延迟，故该数据不经过流水线，直接给到 WB Stage                                 |

### WB 输出

| Port Name        | Target   | Description                                  |
| ---------------- | -------- | -------------------------------------------- |
| regWBDataW[31:0] | ID stage | 经过 4x1 Mux 选择的写回数据，写回到 ID 的 RF |
| regWBEnM         | ID stage | RF 写回使能信号                              |
| rdW[4:0]         | ID stage | RF 的写回 index                              |

## 主流总线

### AXI（Advanced eXtensible Interface）

1. ARM 公司提出的 AMBA（Advanced Microcontroller Bus Architecture）3.0 协议中最重要的部分
2. 是一种面向高性能、高带宽、低延迟的片内总线
3. 分离的地址和数据阶段, 采用 valid，ready 信号握手
4. 使用基于突发的交易类型（Burst-based Transaction），对于突发操作仅需要发送起始 地址，即可传输大片的数据
5. 分离的读通道和写通道，总共有 5 个独立的通道

   - Read Address channel (AR)
   - Read Data channel (R)
   - Write Address channel (AW)
   - Write Data channel (W)
   - Write Response channel (B)

![axi](/Users/fujie/Pictures/typora/pipeline/axi.png)

> AXI 是目前应用最为广泛的片上总线，是处理器核以及高性能 SoC 片上总线的事实标准。

### AHB（Advanced High Performance Bus）

1. ARM 公司提出的 AMBA（Advanced Microcontroller Bus Architecture）2.0 协议中重要的部分
2. 总共有 3 个通道: 写数据总线（HWDATA), 读数据总线（HRDATA）, 地址控制总线（HADDR）
3. 一般情况下，当一个 master 在执行 burst 传输的时候，arbiter 不会打断其传输，可能会导致其他 master 较大的等待

![ahb transfer](/Users/fujie/Pictures/typora/pipeline/ahbTransfer)

> [AHB](https://www.cnblogs.com/HolmeXin/p/9530711.html) 总线是 ARM 公司推出 AXI 总线之前主要推广的总线，虽然目前高性能的 SoC 中 主要使用 AXI 总线，但是 AHB 总线在很多低功耗 **SoC** 中仍然大量使用。

### APB（Advanced Peripheral Performance Bus）

1. ARM 公司提出的 AMBA（Advanced Microcontroller Bus Architecture）协议中重要的部分
2. 主要用于低带宽周边外设之间的 连接，例如 UART 等
3. 不像 AXI 和 AHB 那样支持多个主模块, 唯一的主模块就是 APB 桥
4. 两个时钟周期传输，无须等待周期和回应信号
5. 控制逻辑简单，只有 4 个控制信号

![apb](/Users/fujie/Pictures/typora/pipeline/apb.png)

> 低速设备总线的事实标准，目前很多片上低速设备和 IP 均使用 APB 接口

### 优缺点总结

| 总线名称 | 优点                       | 缺点                                            |
| -------- | -------------------------- | ----------------------------------------------- |
| AXI      | 高性能，吞吐量高           | 1. 控制复杂、容易死锁<br/>2. 五个通道硬件开销大 |
| AHB      | 在高性能低功耗领域广泛使用 | 握手信号比较别扭                                |
| APB      | 控制逻辑简单               | 低俗总线吞吐率低                                |

## ICB

### 命令通道

| 信号名 | 方向   | 宽度 | 介绍           |
| ------ | ------ | ---- | -------------- |
| sReady | input  | 1    | 从设备就绪     |
| mValid | output | 1    | 主设备信号有效 |
| read   | output | 1    | 写或读         |
| addr   | output | DW   | 地址           |
| wData  | output | DW   | 写数据         |
| wMask  | output | DW/8 | 写 Mask        |

### 反馈通道

| 信号名 | 方向   | 宽度 | 介绍             |
| ------ | ------ | ---- | ---------------- |
| mReady | output | 1    | 从设备就绪       |
| sValid | input  | 1    | 主设备信号有效   |
| rError | input  | 1    | 从设备读数据错误 |
| rData  | input  | DW   | 从设备读数据     |
