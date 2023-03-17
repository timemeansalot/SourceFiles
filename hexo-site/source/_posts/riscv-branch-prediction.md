---
title: RISCV分支预测器设计
date: 2023-03-13 16:15:33
tags: RISCV
---

![1 bit predictor](https://s2.loli.net/2023/03/15/ABW43YhqrETUZgJ.png)

- 分支预测器的作用
- 主流的分支预测器
- 开源项目中使用的分支预测器

<!--more-->

**目录**
[TOC]

# To Do Lists

- [ ] 参考 C910, xs, rocket chip, nutshell, e203 的分之预测设计
- [ ] 了解一些有名的分支预测器的设计，如 ITTAGE
- [ ] 看分支预测设计的论文
- [x] 数学公式: 分之指令的频率和预测失败的概率以及整体的预测水平; 不同预测准确度的分支预测器的效果： 不同的分支预测准确率从 50%到 95%，预测的效果差距是否很大
- [ ] performance analysis: digital design and computer architecture: riscv edition page 476, 7.5.4; lecture 14 page 45, Pipelined performance Example

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

# 分支预测器对流水线性能的影响

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

![cpi over bp accuracy](https://s2.loli.net/2023/03/15/74SaG9DQpFMXn5h.png)

## 流水线周期$T_c$

![Time delay for each component](https://s2.loli.net/2023/03/15/F4uTR8pC5cMwDWg.png)
![Includes always-taken br prediction, early branch resolution, forwarding, stall logic](https://s2.loli.net/2023/03/15/2FCHaxsKAmQfO6X.png)

$$
\begin{align*}
T_c = max\{&T_{IF}, T_{ID}, T_{EXE}, T_{MEM}, T_{WB}\}\\
=max\{\\
&t_{pcq}+t_{mem}+t{setup}\\
&\mathbf{\underline{2(t_{RFread}+t_{mux}+t_{eq}+t_{AND}+t_{mux}+t_{setup})}}\\
&t_{pcq}+t_{mux}+t_{mux}+t_{ALU}+t_{setup}\\
&t_{pcq}+t_{mem}+t_{setup}\\
&2(t_{pcq}+t_{mux}+t_{RFwrite}+t_{setup})\}\\
\mathbf{T_c}=\mathbf{T_{ID}}&=550ps
\end{align*}
$$

**重要提示：<u>ID</u> 不应该是关键路径，通常<u>IF</u> 或<u>MEM</u> 可能是关键路径。可以轻松地将 ID 分解为多个 cycle，但很难将 MEM 分解为多个 cycle。**

在此设计中，我们犯了 2 个错误，导致 ID 成为关键路径：

1.我们在 ID 中做分支决策

- **Nutshell** 在 EXE 中做分支决策，它的 BRU 可以是一个单独的单元，也可以复用 ALU 来计算分支决策和目标 PC。
- **Nutshell** 将分支决策从 EXE 传递给 WB（WB 还从 CSR 和 MOU 收集其他重定向信息），然后 WB 将目标 PC 发送到 IF

2. RF 在前半个周期写入、后半个周期读出 -> ID 只有一半的时钟周期来完成它的工作，所以它的 CPI 需要乘 2

- [Toast-RV32i](https://github.com/georgeyhere/Toast-RV32i) 在 clk 的 posedge 上写入 RF，使用组合逻辑读取 RF，当 i_addr == o_addr 通过一个 2 选 1 选择器直接选择 write_data 作为 read_data

## 在何时做分之判断，ID or EXE？

如果不在 ID 做分支判读，而是在 EXE 做分支判断，则得到的平均 CPI 如下：

$$
\begin{align*}
CPI_{branch}&=1*0.75+3*0.25=1.5\\
CPI_{average}&=0.25*1.4+0.1*1+0.11*1.5+0.02*2+0.52*1 = 1.175
\end{align*}
$$

是之前平均 CPI 的 `1.175/1.5`=1.02 倍，并没有显著增加$CPI_{average}$.  
~~但是在 EXE 做分支判断可以<u>**复用 ALU 的硬件**</u>并且<u>**缩短 critical path 从而降低$T_c$**</u>~~

但是在 EXE 做分支判断可以<u>**复用 ALU 的硬件**</u>并且<u>**critical path 从 ID 变成 EXE, 可能会降低$T_c$**</u>，因此建议在 EXE 做分支判断。

$$
T_{program}=Amount_{instructions}*CPI_{average}*T_{c}
$$

# 主流的分支预测器: 预测准确率和其对 CPI 的影响

> 准确的分支预测器 -> 减少错误预测 -> 减少 pipeline flush -> 减少 CPI

## 静态预测器

> 静态预测器不会根据指令实际执行的情况，调整其预测的结果，所有预测在程序执行之前就已经做好了

1. 始终不跳转(always not token): PC+=4
   - 正确预测：0 misprediction penalty
   - 错误预测：3 misprediction penalty(branch decision make in EXE)
2. 后向分支跳转，前向分支不跳转 BTFN(backward taken, forward not taken): 对于 B-Type 指令，如果 offset[31] 为 1，则 offset 为负, 代表其是向后分支，否则向前

## 动态预测器

> 动态预测器会根据指令实际执行的结果、历史信息来做跳转判断

### 一位预测器

Last time prediction(single-bit)

1. 记录上次跳转的结果，90% accuracy
2. accuracy <u>for loop</u> = (N-2)/N
   - 第一次、最后一次都会判断错误
   - N(循环深度) 很大时，准确率 100%

### 两位预测器(bimodal prediction)

> 1bit 预测器当 N 很小时，会出现震荡

1. 记录上次跳转的结果，85%~90% accuracy
2. accuracy <u>for loop</u> = (N-1)/N
   - N 很小时，准确率也有 50%

## 更高级的动态预测器

### BTB

> 对于 B-Type 指令，跳转如果发生的时候，其目的地址(target PC)是不变的，因此可以将目的地址保存到 BTB(branch target buffer)中, 这样只用判断跳转是否发生，不用计算跳转目的地址了。  
> 此外，如果某个 PC 在 BTB 里有其对应的表项，则也能判断该 PC 对应一条分支指令

![BTB](https://s2.loli.net/2023/03/16/hgawQA75So6LuEf.png)

### RAS

### TAGE

[TAGE](http://www.irisa.fr/caps/people/seznec/JILP-COTTAGE.pdf) (Tagged Geometric History Branch Predictor) was introduced in a 2006 paper.

how long should the branch history be?

- On the one hand, longer histories enable accurate predictions for some **harder-to-predict branches**.
- On the other hand, with a longer history, the predictor must track more branch scenarios and thus spend more time <u>warming up</u>, reducing accuracy for **easier-to-predict branches**.

This fundamental branch prediction tradeoff was the inspiration behind **hybrid branch predictors** which use multiple branch histories

[What makes TAGE so great](https://comparch.net/2013/06/30/why-tage-is-the-best/):

1. Entry tagging
2. Entry selection
3. Longer maximum history

### ~~ITTAGE~~

### ~~SC~~

## What accuracy and CPI improve that a better BP can get over our simple static predictor

TODO: make a table or char table

# 开源项目采用的预测器: 准确率和 CPI

## 果壳

IF 占两级
TODU: 看果壳的前段设计, 进行分析

## 香山

## 蜂鸟 E203

- 后向分支跳转，前向分支不跳转
- 对于 JAL，JALR -> 100% taken

## ARM M55(2021)

- pipeline 是 4cycle，分支延迟是 1 个 cycle，不需要分支预测器
- 在一些特定情况下，可以主动设置支持 [LOB](https://armkeil.blob.core.windows.net/developer/Files/pdf/white-paper/introduction-to-armv8-1-m-architecture.pdf)(low overhead branch) extension: low overhead loops and additional branch instructions
  -> 通过硬件处理 loop 地址和 loop count，减少了`LE`指令的执行

[EEMBC-TeleBench LOB performance analysis](https://developer.arm.com/documentation/107564/0100/Low-Overhead-Branch--LOB--performance-analysis/EEMBC-TeleBench-LOB-performance-analysis)
![](https://documentation-service.arm.com/static/62710b867e121f01fd22e838?token=)
上述基准测试主要基于循环，当引入 LOB 时，通过优化循环执行和减少分支开销来提高性能.  
使用高端处理器的分支预测特性也可以获得类似的性能提升。然而，分支预测硬件通常对处理器设计有更大的面积和功耗影响.

Execution overhead cycle for the loop:

| LE (loop end) with LOB cache enabled | LE (loop end) without LOB cache enabled |
| ------------------------------------ | --------------------------------------- |
| 0.04%                                | 5.12%                                   |

## ARM A76

![A76 BPU](https://s2.loli.net/2023/03/15/HIDYNUkJPX1K5Qu.png)

- pipeline 是 13 个 cycle，misprediction penalty 是 11 个 cycle
- 小的 BTB 返回的速度更快，大的 BTB 准确度更高

# 我们的设计

1. 采用<u>静态分支预测</u>或者<u>简单的动态分支预测器</u>如（2bit 分支预测器），不考虑全局历史分支（需要很多额外的硬件、导致$T_c$增加）
2. 尽管分支预测器比较简单，其预测准确率也能满足要求（不会显著增加$CPI_{average}$）
   - 流水线级数很浅，misprediction penalty 最多是 2
   - 非超标量（每周期取指一条），分之判断错误需要冲刷的指令条数顶多 2 条

分支预测器准确率对平均 CPI 的影响如下：

$$
CPI_{B}=P_B[a*1+(1-a)*penalty]=P_B*penalty+\underline{\mathbf{P_B*(1-penalty)}}*a
$$

- $P_B$：分支指令占所有指令的比重
- a: 分支预测器预测正确的概率
- penalty：分支预测器预测失败，冲刷流水线的代价
- $CPI_B$：分支指令对平均 CPI 的贡献
