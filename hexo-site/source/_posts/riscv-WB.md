---
title: RISC-V写回级
date: 2023-04-04 09:35:30
tags: RISC-V
---

## RISC-V WB Stage 设计

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

> 由于 ID 级的 RF 需要一个 cycle 才可以写入，因此 WB Stage 的 output 被定义为 wire 类型，从而避免额外一个 cycle 的 RF 写入延迟，此时 WB 变成纯组合逻辑

TODO: 在引入了 CSR 单元之后，写回的来源也可能是来自于 CSR 寄存器的读数结果
