---
title: riscv-branch-prediction
date: 2023-03-13 16:15:33
tags: RISCV
---

TBD
<!--more-->
<!-- toc -->
**Table of Contents**
[TOC]

# To Do Lists

- [ ] 参考 C910, xs, rocket chip, nutshell, e203 的分之预测设计
- [ ] 了解一些有名的分支预测器的设计，如 ITTAGE
- [ ] 看分支预测设计的论文
- [ ] 数学公式: 分之指令的频率和预测失败的概率以及整体的预测水平; 不同预测准确度的分支预测器的效果： 不同的分支预测准确率从 50%到 95%，预测的效果差距是否很大
- [ ] performance analysis: <<digital design and computer architecture: riscv edition>> page 476, 7.5.4; lecture 14 page 45, Pipelined performance Example

# Branch Method

## Always not taken

1. PC+=4
2. detect branch result as soon as possible -> **reduce misprediction penalty**

   - if branch result is known at EXE stage, 2 following instructions must by flushed
   - if branch result is known at ID stage, 1 following instructions must by flushed
   - we can even add a mux in front of instruction memory to choose the branch target PC from ID stage, then the misprediction penalty is 0

### Resolve branch at ID stage

1. advantages: reduce misprediction penalty -> reduce CPI(clock per instruction)
2. disadvantages:

   - <u>maybe</u> increase clock period
   - Additional hardware cost in the ID stage
     - branch taken or not <- maybe need data forwarding to compare
     - branch target PC <- need a adder to calculate target PC

# Pipelined performance analysis

An important program consists of:

- 25% loads
- 10% stores
- 11% branches
- 2% jumps
- 52% R-type or I-type

Suppose:

- 40% of loads used by next instruction
- 25% of branches mispredicted
- All jumps flush the next instruction fetched -> $CPI_{jump}=2$

## CPI Calculation

> Ideal pipeline processor has a CPI of <u>**1**</u>.

1. Load/Branch CPI = 1 when no stall/flush, 2 when stall/flush.
   $$
   CPI_{lw}=1*0.6+2*0.4 = 1.4\\
   CPI_{branch}=1*0.75+2*0.25=1.25
   $$
2. average CPI is the weighted sum over each instruction
   $$
   CPI_{average}=0.25*1.4+0.1*1+0.11*1.25+0.02*2+0.52*1 = 1.15
   $$

## Cycle Time

![Includes always-taken br prediction, early branch resolution, forwarding, stall logic](https://s2.loli.net/2023/03/15/2FCHaxsKAmQfO6X.png)

$$
\begin{align*}
T_c = max\{&T_{IF}, T_{ID}, T_{EXE}, T_{MEM}, T_{WB}\}\\
=max\{\\
&t_{pcq}+t_{mem}+t{setup}\\
&\mathbf{\underline{2(t_{RFread}+t_{mux}+t_{eq}+t_{AND}+t_{mux}+t_{setup})}}\\
&t_{pcq}+t_{mux}+t_{mux}+t_{ALU}+t_{setup}\\
&t_{pcq}+t_{mem}+t_{setup}\\
&2(t_{pcq}+t_{mux}+t_{RFwrite})\}\\
\mathbf{T_c=T_{ID}}
\end{align*}
$$

![Time delay for each component](https://s2.loli.net/2023/03/15/F4uTR8pC5cMwDWg.png)
Check the table above, we can calculate $T_c=550ps$.

**Important Notes: <u>ID</u> should not be the critical path, usually <u>IF</u> or <u>MEM</u> could be the critical path. You can easily break ID into many cycle while you can hardly brewk MEM into multiple cycle.  
In this design, we make 2 mistakes which result the ID to be the critical path:**

1. we do branch decision in ID

- **Nutshell** do branch decision in EXE, its BRU can be a single unit or reuse the ALU to calculate branch decision and target PC.
- **Nutshell** pass the branch decision from EXE to WB(WB also collect other redirect info from CSR and MOU), then WB send the target PC to IF -> misprediction penalty is 3 cycle.

2. we read the RF at the second cycle, write the RF at the first cycle -> the ID has only half of the clock cycle to do its job

- [Toast-RV32i](https://github.com/georgeyhere/Toast-RV32i) write to RF on the posedge of clk, read RF using combinational logic, bypass input to output when i_addr == o_addr

## Compare Instruction Time: branch in ID vs branch in EXE

# Different branch predictor and the result CPI

> accurate branch predictor -> reduce misprediction -> reduce flush -> reduce CPI

## Static predictor

### always not token

PC+=4

### backward branch taken, forward branch not taken

For B-Type instructions, if offset[31] is 1, offset is negative -> backward branch, else forward  
For JAL, JALR -> 100% jump

## Dynamic predictor

### one bit predictor

### two bit predictor

1. Oscillator of one bit predictor

## More advanced dynamic predictor

# Open source project predictor and their CPI

## nutshell

## xs

## E203

Use backward branch taken, forward branch not taken\_.

## Alibaba C910

## Arm M55

## Arm A76
