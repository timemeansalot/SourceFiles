---
title: IC笔记2
date: 2023-10-23 10:41:16
tags:
---

IC笔记2

<!--more-->

# Timing

假设寄存器的输入为D，输出为Q，有寄存器A到寄存器B的数据通路

## Setup Time

1. 定义：在clock的上升沿前setup时间，D必须保持稳定不在变化，否则寄存器的输出Q会处于不稳定态(metastability)
2. 什么时候会违反Setup Time 约束(setup violation): 本质原因是<u>数据从A到达B太迟了</u>，
   导致B寄存器要求的$D_B$应该稳定的时刻，数据还在发生变化

   - 时钟周期T太短
   - 寄存器之间的组合逻辑太长，传播时延太大
   - 假设$T_{skew}>0$，即B的clock由于线路延时比A的clock后到达，则$T_{skew}$的存在让Hold Time**更容易满足**

   $T_{cq\_A}+T_{logic}+T_{setup} < T+T_{skew}$，不考虑$T_{cq}, T_{skew} \rightarrow T_{logic}<T-T{setup}$

   - $T_{cq\_A}$: 寄存器A时钟上升沿到$Q_A$开始变化的时间

## Hold Time

1. 定义：在clock的上升沿后hold时间，D必须保持稳定不变
2. 违反Hold Time约束的原因：<u>A->B的第二笔数据太快到达B了</u>，导致上一个cycle的数据被冲刷掉:

   - 寄存器之间组合逻辑太短，时延太短
   - 假设$T_{skew}>0$，即B的clock由于线路延时比A的clock后到达，则$T_{skew}$的存在让Hold Time**更难满足**

   $T_{cq\_A}+T_{logic}<T_{hold}+T_{skew}$，不考虑$T_{cq}, T_{skew} \rightarrow T_{logic}>T_{hold}$

   > PS: 考虑$T_{hold}$的时候，没有考虑周期T，<u>因为是第二笔数据到达太块，第二笔数据跟B采样的时候，是同一个周期</u>

3. 总结：时序上应该满足$T_{hold} < T_{logic} < T-T_{setup} , T_{setup}+T_{hold}<T$

![](https://s2.loli.net/2023/10/23/MgkdGxQAlyKbnZo.png)

## 如何计算最大频率

1. $f=1/T$, 找到满足时序约束的最小的T即可
2. 如上所述，T跟$T_{hold}$没有关系，只跟$T_{setup}$有关系:  
   $T>T_{logic}+T_{setup}-T_{skew}\rightarrow f<1/T=1/(T_{logic}+T_{setup}-T_{skew})$

# Latch to FF(Flip Flop)

1. 结构
   - Latch(PS: Latch 其实有多种实现结构)
     ![](https://electronicsforu.com/wp-contents/uploads/2017/08/SR-latch.jpg)
   - FF
     ![](https://www.electronicsforu.com/wp-contents/uploads/2017/08/SR-flip-flop.png)

