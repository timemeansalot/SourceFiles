---
title: RISCV总线
date: 2023-04-06 15:45:24
tags: RISCV
---

![System Bus](https://s2.loli.net/2023/04/10/I7sfhHlEuwZcPaW.png)
RISCV 总线设计

<!--more-->

## 主流总线

### AXI（Advanced eXtensible Interface）

1. ARM 公司提出的 AMBA（Advanced Microcontroller Bus Architecture）3.0 协议中最重要的部分，
2. 是一种面向高性能、高带宽、低延迟的片内总线。
3. 分离的地址和数据阶段。
4. 支持地址非对齐的数据访问，使用字节掩码（Byte Strobes）来控制部分写操作。
5. 使用基于突发的交易类型（Burst-based Transaction），对于突发操作仅需要发送起始 地址，即可传输大片的数据。
6. 分离的读通道和写通道，总共有 5 个独立的通道。
7. 支持多个滞外交易（Multiple Outstanding Transaction）。
8. 支持乱序返回乱序完成。
9. 非常易于添加流水线级数以获得高频的时序。

> AXI 是目前应用最为广泛的片上总线，是处理器核以及高性能 SoC 片上总线的事实标准。

### AHB（Advanced High Performance Bus）

1. ARM 公司提出的 AMBA（Advanced Microcontroller Bus Architecture）2.0 协议中重要的部分
2. 总共有 3 个通道
3. 单个时钟边沿操作
4. 非三态的实现方式
5. 支持突发传输、支持分段传输以及支持多个主 控制器等

> AHB 总线是 ARM 公司推出 AXI 总线之前主要推广的总线，虽然目前高性能的 SoC 中 主要使用 AXI 总线，但是 AHB 总线在很多低功耗 **SoC** 中仍然大量使用。

### APB（Advanced Peripheral Performance Bus）

1. ARM 公司提出的 AMBA（Advanced Microcontroller Bus Architecture）协议中重要的部分
2. 主要用于低带宽周边外设之间的 连接，例如 UART 等
3. 不像 AXI 和 AHB 那样支持多个主模块, 唯一的主模块就是 APB 桥
4. 两个时钟周期传输，无须等待周期和回应信号
5. 控制逻辑简单，只有 4 个控制信号

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
