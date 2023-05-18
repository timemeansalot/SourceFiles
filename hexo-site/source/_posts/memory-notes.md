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

![cache arch](https://s2.loli.net/2023/05/17/5ZLsH8INkB3abgY.png)

1. cache has a tag which is part of the main-memory address,  
   cache line may have other bits like: valid or dirty
2. L1 cache can be separated into I-Cache and D-Cache
   - avoid instruction or data to occupy the whole cache and let the other has no cache
   - instruction and data cache can all be close to the processor, both are fast
   - L1 cache can't be too big:
     - L1 cache has to be fast to fit in the pipeline
     - capacity grows, speed decrease
3. last level cache may be shared by multi-cores
   - avoid only one core occupy the whole cache
   - cache consistency
4. cache organization
   - multi-level cache has the same data
     cache consistency check is very simple: only check the last level of cache is OK
   - only one level of cache has the data, other level of cache don't has that data,
   - mix of the above two method
5. manage policy:

   - full-associative: main memory chunk can map into every cache block
     - higher hit rate
     - more complexity: more comparator, bigger mux
     - bigger latency
   - directly-mapped: memory chunk can only mapped into one specific cache block
   - set-associative: memory chunk can only mapped into one set, but any cache block inside that set.
     a W-way cache:
     - W==N: full-associative
     - W==1: directly-mapped

   ![](https://s2.loli.net/2023/05/16/Rfg6NoOzwM3BU1V.png)

6. write handling:
   - write through: when cache is write into, all higher level memory must be write into
     - easier for check cache consistency, prevents any data discrepancy from arising
     - waste energy and bandwidth
   - write back: write back to high level of memory only when evicting
     - save energy and bandwidth
     - more complicated when design cache
     - need dirty flag
7. use cache can reduce memory access time, the hit rate is very important in cache design,  
   but hit rate and capacity are zero-sum of access latency of cache

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
5. PCM(phase charge memory) <- emerging memory technology
   - Write data by pulsing current $dQ/dt$
   - Read data by detecting resistance: high resistance for 1, low resistance for 0
   - better scalable than DRAM, no need to refresh
   - longer latency, short lifetime(can only write into a few times)

## Virtual Memory

1. programmer see virtual memory only:
   - programmer don't know what hardware their program will running on, so they can't suspect the physical memory
   - their are many programs running at the same time, programmer don't know the memory state when the program is running
2. it's the OS to manage the mapping of virtual memory and physical memory, the OS use _Page Table_ to manage address mapping
   - page table entry has valid bits to indicate if virtual memory is mapped to physical memory
   - valid bit is 0 -> <u>page fault</u> -> trap to OS -> bring in missing page -> update page table
     ![](https://s2.loli.net/2023/05/18/tqbYvi3mrswFea6.png)
   - page entry has <u>dirty bits</u> to indicate if the page in memory has been modified,
     when the page is evicted back to disk, only modified page will be write back
   - **page replacement algorithm**: when physical frame is full, we need an algorithm to choose a
     victim frame to swap out to disk.
     1. FIFO: will cause <u>Belady's Anomaly</u>(frame size grows, page fault grows)
     2. Optimal algorithm: can't implement this, we don't know the future
     3. LRU:
        - method 1: each page-table entry has a counter, every time page is referenced through
          this entry, set the entry counter to clock -> the least recently used page has the
          smallest counter
        - method 2: keep a stack of page numbers in double-link form -> page referenced, 
         move the page number to stack top
   - for multi-user system, the OS has a page table for each user, so each user
     can share the whole physical memory
     ![](https://s2.loli.net/2023/05/18/QZ5MiNx6cT2gfHG.png)
3. memory size can't be to small, or the complexity of manage virtual/physical mapping is difficult.
   modern processor has virtual memory page size equal to 64b
4. we need TLB(which is a cache) to accelerate the translation from virtual memory to physical memory
5. virtual memory space is much larger than physical memory space.
6. trashing: if physical memory is too small, then some virtual memory page must be swap in and out,
   this will degrade system performance much
