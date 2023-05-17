---
title: 计算机内存
date: 2023-05-16 20:30:50
tags: CA
---

计算机内存是处理器数据的存储仓库: processor <-- communication --> memory

<!--more-->

## Memory Fundamentals

1. trade-off: price, capacity, performance

   - if we fix price, then capacity and performance is zero-sum
   - performance: latency, bandwidth, parallelism, $bandwidth = parallelism/latency$

2. multi-level memory system: because of the trade-off of memory, if we want both performance and capacity, we must use multi-level memory:
   - cache: small but fast
   - main memory: big bug slow
   - disk: large and very slow
   - ![memory hierarchy](https://s2.loli.net/2023/05/16/w67oIMLc9lzJgUj.png)

## Cache

1. L1 cache can be separated into I-Cache and D-Cache
   - avoid instruction or data to occupy the whole cache and let the other has no cache
   - instruction and data cache can all be close to the processor, both are fast
2. last level cache may be shared by multi-cores
   - avoid only one core occupy the whole cache
   - cache consistency
3. cache organization
   - multi-level cache has the same data
     cache consistency check is very simple: only check the last level of cache is OK
   - only one level of cache has the data, other level of cache don't has that data,
   - mix of the above two method
4. manage policy:

   - full-associative: main memory chunk can map into every cache block
   - directly-mapped: memory chunk can only mapped into one specific cache block
   - set-associative: memory chunk can only mapped into one set, but any cache block inside that set.  
     a W-way cache:
     - W==N: full-associative
     - W==1: directly-mapped

   ![](https://s2.loli.net/2023/05/16/Rfg6NoOzwM3BU1V.png)

5. write handling:
   - write through: when cache is write into, all higher level memory must be write into
     - easier for check cache consistency, prevents any data discrepancy from arising
     - waste energy and bandwidth
   - write back: write back to high level of memory only when evicting
     - save energy and bandwidth
     - more complicated when design cache
     - need dirty flag
6. use cache can reduce memory access time, the hit rate is very important in cache design

## DRAM

1. 1T1C: made of 1 transistor and 1 capacitor
   - capacitor leaks, this is why DRAM is **dynamic**
   - need refresh at least 1 once in 64ms
   - higher density than SRAM(6T)
2. operations of DRAM is controlled by **MC(memory controller)**
   - activate
   - pre-charge
   - read/write
3. level of DRAM
   - channel: has unique address, control and data path
   - rank
   - bank
     ![DRAM structure](https://s2.loli.net/2023/05/16/AwulDzrFVa2C4G5.png)
4. usually DRAM is not on chip, it's on motherboard
   - high energy, long latency, low bandwidth
   - 3D-Stacking: put DRAM on top of processor
5. PCM(phase charge memory)
   - represent 0, 1 by resistance, resistance is effected by current
   - high resistance for 1, low resistance for 0
   - better scalable than DRAM, no need to refresh
   - longer latency, short lifetime(can only write into a few times)

## Virtual Memory

1. programmer see virtual memory only:
   - programmer don't know what hardware their program will running on, so they can't suspect the physical memory
   - their are many programs running at the same time, programmer don't know the memory state when the program is running
2. it's the OS to manage the mapping of virtual memory and physical memory, the OS use _Page Table_ to manage address mapping
3. memory size can't be to small, or the complexity of manage virtual/physical mapping is difficult.
   modern processor has virtual memory page size equal to 64b
4. we need TLB(which is a cache) to accelerate the translation from virtual memory to physical memory
5. virtual memory space is much larger than physical memory space.
6. trashing: if physical memory is too small, then some virtual memory page must be swap in and out,
   this will degrade system performance much
