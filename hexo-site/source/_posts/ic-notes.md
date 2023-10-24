---
title: 数字集成电路笔记
date: 2023-10-22 16:13:38
tags:
  - RISC-V
  - IC
---

数字集成电路笔记

<!--more-->

# 面经

## 数字分频器

1. [笔记链接](https://cloud.tencent.com/developer/article/2284221)
2. 作用：将高频信号分频为低频信号；配合DSP使用可以得到高频信号
3. 偶数分频:
   - 方法1：通过寄存器延时获得2,4,8,...,等分频
   - 方法2：通过计数器实现分频；如果需要实现6分频，则需要一个计数器，从0开始计数，<u>到2的时候</u>，将目标信号进行翻转即可
4. 奇数分频:
   - （高低占比不是各50%）: 计数器为0、(n-1)/2的时候，都将目标信号翻转即可，例如下图3分频，计数器为0，2的时候，翻转即可
     ![](https://developer.qcloudimg.com/http-save/yehe-admin/361cbbc5d5d1f93432bc1694607d3887.png)
   - （高低占比是各50%）:需要2个计数器，分别在上升沿跟下降沿+1，这两个计数器到达n-1时，信号翻转；将得到的两个信号进行或操作
     ![](https://developer.qcloudimg.com/http-save/yehe-admin/3c0dd711314b7663ba92f514f5bd83b1.png)

## 边沿检测

1. 作用：检测信号的上升沿、下降沿
2. 实现: `din_r`是`din`延迟1拍的信号
   ```verilog
       assign up_edge   = ~din_r & din;
       assign down_edge = din_r & ~din;
       assign both_edge = din_r ^ din;
   ```

## CDC(Clock Domain Crossing)问题

### 单 bit 信号

1. 慢->快：慢clock的信号传到快clock的时钟域，一定可以被采样到；所以需要考虑的是**采样的质量**
2. 实现：为了避免亚稳态的出现，通常采用<u>打2拍的方式</u>

![](https://developer.qcloudimg.com/http-save/yehe-admin/ac0110fd2cb814f2bb063ac5a5fee2ab.png)

## FIFO 问题

## STA(Static Timing Analysis)

### contamination delay($T_{cd}$) & propagation delay($T_{pd}$)

假设有一个buffer，其输入为A，输出为Y

- $T_{cd}$: A开始变化到Y开始变化的时间
- $T_{pd}$: A开始变化到Y变化到最终稳定的时间

![](https://electrotrick.files.wordpress.com/2017/08/buffer.png)

### Hazard & Glitch

- Hazard：<u>电路的特性</u>，在组合电路中，各个输入端变化不是严格同步的，导致输出可能会存在亚稳态
- Glitch：Hazard导致的输出Y出现的波动，由于输入不是同时到达组合电路的，因此组合电路的输出可能会有**瞬时变化**

![](https://electrotrick.files.wordpress.com/2017/08/glitch-timing.png)

### Sequential logic delays

假设寄存器的输入为D，输出为Q

- $T_{setup}$, $T_{hold}$: D需要在clk上升沿到达之前$T_{setup}$保持稳定，在clk上升沿之后$T_{hold}$保持稳定，否则Q会进入亚稳态(metastability)
- $T_{cq}$: 又叫做<u>clock to output dealy</u>, 时钟clk上升沿一半的时刻到Q变化到一半的时刻（clk上升沿到Q开始变化的时刻）
- $T_{setup}$, $T_{hold}$, $T_{cq}$都可以在寄存器的说明书(datasheet)里找到

![](https://electrotrick.files.wordpress.com/2017/09/setup-violation.png)

### TODO: use K-Map to reduce Glitch

### 参考资料:

- [Static Timing Analysis](https://electrotrick.wordpress.com/tutorial-series/static-timing-analysis/)

## Name

1. [笔记链接]()

# 体系结构

# 参考资料

## 面经

1. [数字IC经典电路设计](https://cloud.tencent.com/developer/column/99554)

## 体系结构
