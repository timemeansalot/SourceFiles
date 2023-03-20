---
title: RISCV存储设计
date: 2023-03-13 16:15:40
tags: RISCV
---

<!--more-->

# To Do Lists

- [ ] 参考 C910, xs, rocket chip, nutshell, e203 的内存系统设计
- [ ] 看低功耗内存设计的论文
- [ ] riscv address align define, how the open source project solve address align problem
- [ ] Virtual Memory

# 虚拟内存

## 为什么需要虚拟内存

1. 对于 RAM 来说，应用太大（放不下）：根据局部性原理，我们只把程序部分内容放入到 RAM 中就可以满足程序运行，具体实现有分段、分页两种手段
   - 分段：在 RAM 中为不同应用程序分配不同的连续内存空间，各个应用程序之间彼此互不干扰；缺点是会产生外部碎片
   - 分页：物理内存空间和虚拟内存空间都被分成很多页（比如 4kb）

## TLB

> Without TLB, we have to access the main memory twice to get the target content: the first access to get the target address, the second access to get the target content.

### TLB Addressing

1. Virtual Addressing: the CPU use the virtual address to access the **data cache**. Only when cache miss, the CPU access the TLB to try to get to missing data.
2. Physical Addressing: each time, the CPU access the TLB first to get the data address, then use the data address to access the cache.
