---
title: 付杰周报-20231028
date: 2023-03-08 14:45:34
tags: RISC-V
---

[TOC]

# 1 MCU设计方案

![](https://s2.loli.net/2023/12/02/1S3R8MJuh5F6LKA.png)

## 1.1 单发射流水线MCU集成AXI需要的场景

1. 写到ACC的时候，由于地址不保证连续，所以不能采用burst写
2. 从PPM(ping pong memory)读的时候，地址是连续的，可以采用burst读

### 1.1.1 什么场景下会触发AXI Burst传输

1. 对于顺序处理器核而言，每个cycle至多有一条riscv load指令
2. 访问PPM的延迟比访问D-Memory的延迟高
3. 配置ACC的指令流:
   - 情形1
     ```bash
     load rd, PPM[addr]
     store rd, ACC[addr]
     ...
     load rd, PPM[addr]
     store rd, ACC[addr]
     ```
   - 情形2
     ```bash
     load rd, PPM[addr]
     load rd, PPM[addr]
     ...
     store rd, ACC[addr]
     store rd, ACC[addr]
     ```
     > PS: 从PPM read指令后面，还需要对read的数据进行解析得到addr跟data，才可以写入到ACC
4. burst传输的场景:
   - 通过burst读，顺序地读取多个地址的数据(预读取)
   - **Optional**: read操作不会stall流水线

### 1.1.2 顺序单发射处理器核如何支持burst传输

1. 需要在MCU跟AXI Channel之间增加AXI Master Interface
2. Interface用于:
   - 支持read burst
   - 避免burst传输时MCU stall
   - 支持write pipeline
   - 解决MCU跟ACC、PPM之间的跨时钟域问题

### 1.1.3 哪条指令会触发burst传输

1. CORTEX-A9有ldm/stm(load multiple, store multiple)指令来触发AXI burst操作
2. MCU可以根据load指令&地址范围处于PPM来触发burst read，`burst length=16`
3. 增加自定义指令来支持对PPM的burst读:
   - 修改decoder
   - 修改编译器
   - 灵活

### 1.1.4 burst传输时MCU是否会Stall

1. 处理器是否支持Out-of-Order
2. 指令之间的相关性
3. AXI Interface设计

## 1.2 MCU AXI的设计总结

![](https://s2.loli.net/2023/12/02/jOINcTw9LEFDpg2.png)

1. 采用burst对PPM进行读取:

   - 当地址空间对应PPM时，Interface会对PPM发起16个beat的Burst读
   - 读回的data会被存放在Interface的异步`Read_FIFO`中
   - FIFO头元素的地址跟MCU的read addr相时，FIFO头部元素pop

2. 采用pipeline的方式对ACC进行写:

   - MCU执行到MEM Stage的时候，会判断地址范围，不会写入到D-Memory，而是通过AXI写通道写到ACC
   - AXI Interface接收MCU发的write addr, write data, write control等信号
   - 写的时候不用收到ACC的反馈即可发起下一笔写
   - Interface若收到AXI Slave的Error信号，会发送给MCU，触发Exception

3. Interface跟Slave之间采用1主多从的拓扑结构:
   - 有译码器根据地址选择slave
   - 没有仲裁器

# 2 Coding

- [x] MCU跟Interface交互的代码
- [ ] AXI Master Interface
- [ ] AXI 总线拓扑结构：译码器
- [ ] Slave跟Interface交互代码
