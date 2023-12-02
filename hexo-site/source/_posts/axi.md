---
title: axi
date: 2023-11-24 23:45:16
tags:
  - RISC-V
  - Bus
  - AXI
---

AXI笔记

<!--more-->

Core需要支持以下的AXI传输特性:

1. 多个Slave访问：arbiter, buffer
2. Out of Order: ID
3. Outstanding transaction
4. multi-clock domain for low power
5. stall the pipeline before finish transaction
6. register slice to pipeline: make this a TODO as I don't fully understand AXI pipeline

- [ ] 给出MEM模块针对AXI的架构图
- [ ] 说明架构图中的模块对应实现了上述AXI的什么特性
- [ ] 查看别的Core支持AXI时做的实现
- [ ] store the config data in internal shadow registers and trigger DMA to pass the data to ACC
- [ ] **能否将AXI改为半双工？**因为我们的顺序核一次要么读、要么写；并且方便的链接到AXI协议

## method 1

1. ACC serves as AXI slave, DMA serves as AXI master, DRAM serves as AXI slave
2. every time ACC needs write/read to SDRAM, CPU triggers the DMA to pass the data from/to ACC
3. bad:
   - every transaction need CPU
   - it sucks when ACC need small amount of data very often, CPU has to trigger DMA very often

## method 2

1. ACC create the write/read request and stores the request in a FIFO
2. the DMA can read from the FIFO and do the data transaction if there is a request
3. bad:
   - transaction TIMING issue
   - another hardware which watch the FIFO to see if there is a transaction needed

## method 3

1. ACC serves as AXI master, and direction write/read to DRAM
2. ways to do this:
   - write RTL of AXI in your ACC
   - use IP of AXI in your ACC
   - use Vivado HLS in your ACC

# 4种AXI Master类型

1. single beat
2. single beat pipelined
3. bursting, single channel
4. bursting, multiple channel

## single beat

1. 特点：burst size等于0，给出地址及控制信号后只包含**一次数据传输**，传输完成之后再发送下一次地址跟控制信号
2. 实现:
   - AxLEN=0
   - WLAST=1, ignore RLAST
   - ignore AxBURST：不需要关注burst类型，也不需要关心burst地址是否跨越4kB边界
3. 优点：功能上是可用的
4. 缺点带宽(throughput)很低: data bus利用率很低，基本上都是空cycle

![](https://zipcpu.com/img/wbm2axisp/single-master-reads.svg)

## single beat pipelined

1. 特点支持outstanding传输：传输反馈(response)没有收到之前就可以发送下一次传输的地址跟控制信号
2. 实现:
   - issue状态机
   - response状态机
   - 同步状态机
   - counter & FIFO用于记录request，并且在收到response的时候使用
   - AxID是常量：保证所有传输是顺序的
3. 优点: data bus带宽理论上可以吃满
4. 缺点: 对Slave要求过于理想（要求slave的两个burst传输之间没有空闲）；  
   eg: Xilinx’s AXI block RAM interface每次burst传输需要`3+N`个cycle，若N=0，则带宽利用率为25%
5. 适用场景：传输地址不是连续（访问image的列数据)、或者下次传输地址未知的场景

## bursting, single channel

1. 特点：支持burst传输（一次地址&控制信号，多次data传输）
2. 实现:
   - 记录当前已经传输的beats数
   - WLAST在最后一次写的时候拉高
3. 地址:
   - wrap & fixed, beats <= 16; increment, beats <= 256
   - 地址不能跨越4kB: 通过配置AxLEN保证
   - <u>PS: 尽可能在一次burst传输中传输尽可能多的beats</u>

## bursting, multiple channel

1. 特点: 通过ID实现乱序传输:

   - outstanding but in order 读写：
     ![image-20231125082444175](https://s2.loli.net/2023/12/01/iDRV5AxdF9hObBw.png)
   - OoO写：不同ID的写传输，其Response可以乱序，但是Wdata不能interleaving
     ![image-20231125080220026](https://s2.loli.net/2023/12/01/Hr37RSFp9wxvXAf.png)
   - OoO读：不同ID的读传输，其Rdata可以interleaving
     ![image-20231125080234460](https://s2.loli.net/2023/12/01/jhB7O3A4MCoLPT2.png)

2. 实现:
   - master需要支持reorder buffer
3. 优点: 适用于一个Master需要同时访问多个slave的场景

4. 缺点: 对AXI Interconnect要求比较高，master可以并行访问slaves时才好用

# MCU设计方案

![](https://s2.loli.net/2023/12/02/FhNOpysj8SG1XmA.png)
## 单发射流水线MCU集成AXI需要的场景

1. 写到ACC的时候，由于地址不保证连续，所以不能采用burst写
2. 从PPM(ping pong memory)读的时候，地址是连续的，可以采用burst读

### 什么场景下会触发AXI Burst传输

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

### 顺序单发射处理器核如何支持burst传输

1. 需要在MCU跟AXI Channel之间增加AXI Master Interface
2. Interface用于:
   - 支持read burst
   - 避免burst传输时MCU stall
   - 支持write pipeline
   - 解决MCU跟ACC、PPM之间的跨时钟域问题

### 哪条指令会触发burst传输

1. CORTEX-A9有ldm/stm(load multiple, store multiple)指令来触发AXI burst操作
2. MCU可以根据load指令&地址范围处于PPM来触发burst read，`burst length=16`
3. 增加自定义指令来支持对PPM的burst读:
   - 修改decoder
   - 修改编译器
   - 灵活

### burst传输时MCU是否会Stall

1. 处理器是否支持Out-of-Order
2. 指令之间的相关性
3. AXI Interface设计

### write to ACC流水

1. MCU执行Store指令，Store的地址范围属于ACC的地址空间
2. MCU执行到MEM Stage的时候，会判断地址范围，不会写入到D-Memory，而是通过AXI写通道写到ACC

## MCU AXI的设计总结

![image-20231202110646792](https://s2.loli.net/2023/12/02/YHsUMTXOQFA2ICl.png)

1. 采用burst对PPM进行读取:

   - 当地址空间对应PPM时，Interface会对PPM发起16个beat的Burst读
   - 读回的data会被存放在Interface的异步`Read_FIFO`中
   - FIFO头元素的地址跟MCU的read addr相时，FIFO头部元素pop

2. 采用pipeline的方式对ACC进行写:

   - AXI Interface接收MCU发的write addr, write data, write control等信号
   - 写的时候不用收到ACC的反馈即可发起下一笔写
   - Interface若收到AXI Slave的Error信号，会发送给MCU，触发Exception

3. Interface跟Slave之间采用1主多从的拓扑结构:
   - 有译码器根据地址选择slave
   - 没有仲裁器

# Coding

- [x] AXI Master Interface
- [ ] MCU跟Interface交互的代码
- [ ] AXI 总线拓扑结构：译码器
- [ ] Slave跟Interface交互代码
