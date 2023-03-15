---
title: riscv-branch-prediction
date: 2023-03-13 16:15:33
tags: RISCV
---

TBD

<!--more-->

**目录**
[TOC]

# To Do Lists

- [ ] 参考 C910, xs, rocket chip, nutshell, e203 的分之预测设计
- [ ] 了解一些有名的分支预测器的设计，如 ITTAGE
- [ ] 看分支预测设计的论文
- [ ] 数学公式: 分之指令的频率和预测失败的概率以及整体的预测水平; 不同预测准确度的分支预测器的效果： 不同的分支预测准确率从 50%到 95%，预测的效果差距是否很大
- [ ] performance analysis: <<digital design and computer architecture: riscv edition>> page 476, 7.5.4; lecture 14 page 45, Pipelined performance Example

# 分支预测

## 预测不跳转(always not taken)

1. PC+=4
2. 尽快检测分⽀结果 -> 减少错误预测惩罚
   - 如果在 EXE 阶段已知分⽀结果，则必须刷新 2 条后续指令
   - 如果在 ID 阶段已知分⽀结果，则必须刷新 1 条后续指令

### 在译码级判断分之结果

1. 优点：减少误预测惩罚(misprediction penalty) -> 减少 CPI(clock per instruction)
2. 缺点：

   - <u>可能</u>增加时钟周期$T_c$
   - 译码阶段的额外硬件成本
     - 判断分之结果：需要比较器、bypass to ID stage
     - 计算目的 PC: 额外的加法器

# Pipelined 性能分析

程序中各种类型的指令概率如下:

- 25% loads
- 10% stores
- 11% branches
- 2% jumps
- 52% R-type or I-type

假设:

- 40%的`lw`指令的结果会被下一条指令用到
- 25%的 branch 指令预测错误
- 所有的 JAL, JALR 会导致其下一条指令刷新-> $CPI_{jump}=2$

## CPI 计算

> 理想的流水线处理器的 CPI= <u>**1**</u>.

1. Load/Branch CPI = 1 when no stall/flush, 2 when stall/flush.
   $$
   CPI_{lw}=1*0.6+2*0.4 = 1.4\\
   CPI_{branch}=1*0.75+2*0.25=1.25
   $$
2. 平均 CPI 是所有类型指令 CPI 的加权平均
   $$
   CPI_{average}=0.25*1.4+0.1*1+0.11*1.25+0.02*2+0.52*1 = 1.15
   $$

## 流水线周期$T_c$

![Includes always-taken br prediction, early branch resolution, forwarding, stall logic](https://s2.loli.net/2023/03/15/2FCHaxsKAmQfO6X.png)

![Time delay for each component](https://s2.loli.net/2023/03/15/F4uTR8pC5cMwDWg.png)

$$
\begin{align*}
T_c = max\{&T_{IF}, T_{ID}, T_{EXE}, T_{MEM}, T_{WB}\}\\
=max\{\\
&t_{pcq}+t_{mem}+t{setup}\\
&\mathbf{\underline{2(t_{RFread}+t_{mux}+t_{eq}+t_{AND}+t_{mux}+t_{setup})}}\\
&t_{pcq}+t_{mux}+t_{mux}+t_{ALU}+t_{setup}\\
&t_{pcq}+t_{mem}+t_{setup}\\
&2(t_{pcq}+t_{mux}+t_{RFwrite})\}\\
\mathbf{T_c}=\mathbf{T_{ID}}&=550ps
\end{align*}
$$

**重要提示：<u>ID</u> 不应该是关键路径，通常<u>IF</u> 或<u>MEM</u> 可能是关键路径。可以轻松地将 ID 分解为多个 cycle，但很难将 MEM 分解为多个 cycle。**

在此设计中，我们犯了 2 个错误，导致 ID 成为关键路径：

1.我们在 ID 中做分支决策

- **Nutshell** 在 EXE 中做分支决策，它的 BRU 可以是一个单独的单元，也可以复用 ALU 来计算分支决策和目标 PC。
- **Nutshell** 将分支决策从 EXE 传递给 WB（WB 还从 CSR 和 MOU 收集其他重定向信息），然后 WB 将目标 PC 发送到 IF -> 错误预测惩罚为 3 个周期。

2. RF 在前半个周期写入、后半个周期读出 -> ID 只有一半的时钟周期来完成它的工作，所以它的 CPI 需要乘 2

- [Toast-RV32i](https://github.com/georgeyhere/Toast-RV32i) 在 clk 的 posedge 上写入 RF，使用组合逻辑读取 RF，当 i_addr == o_addr 通过一个 2 选 1 选择器直接选择 write_data 作为 read_data

## 在何时做分之判断，ID or EXE？

# 主流的分支预测器: 预测准确率和其对 CPI 的影响

> 准确的分支预测器 -> 减少错误预测 -> 减少 pipeline flush -> 减少 CPI

## 静态预测器

### 始终不跳转(always not token)

PC+=4

### 后向分支跳转，前向分支不跳转(backward taken, forward not taken)

对于 B-Type 指令，如果 offset[31] 为 1，则 offset 为负, 代表其是向后分支，否则向前
对于 JAL，JALR -> 100% taken

## 动态预测器

### 一位预测器

### 两位预测器

1.一位预测器会产生震荡

## 更高级的动态预测器

# 开源项目采用的预测器: 准确率和 CPI

## 果壳

## 香山

## 蜂鸟 E203

> 后向分支跳转，前向分支不跳转

## 阿里巴巴玄铁 C910

## ARM M55

## ARM A76
