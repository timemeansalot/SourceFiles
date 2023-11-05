---
title: Cache笔记
date: 2023-11-05 14:20:45
tags:
  - CA
  - NOTES
---

Cache笔记

<!--more-->

# Cache基础知识

# Cache一致性

## 维护一致性的两个原则

1. 写传播 <-通知：一个核心写入到Cache Line之后，必须通知其他核
2. 事物串行化<-锁：多个核写入到同一个Cache Line时，引入锁的机制，保证写入到Cache Line的操作的原子性

## 写传播

## 事物串行化

### 总线嗅探

1. 一个核修改数据之后，需要往总线发送广播，告知其他所有的核
2. 核需要一直监测总线的广播，如果发现一个数据自己也包含，则需要将数据修改成对应的值
3. 缺点：造成总线的压力很大；<u>无法实现事务串行化</u>

### MESI协议

![](https://s2.loli.net/2023/11/05/YDKMstmg5zPBAG8.png)

1. 基于总线嗅探机制

2. 是四个状态单词的开头字母缩写，分别是：

   - Modified，已修改
   - Exclusive，独占
   - Shared，共享
   - Invalidated，已失效

3. 在Modified和Exclusive状态下修改数据，不需要广播到其他的核心、降低了总线的压力

# 参考文献

1. [CPU 缓存一致性](https://www.xiaolincoding.com/os/1_hardware/cpu_mesi.html#mesi-%E5%8D%8F%E8%AE%AE)
