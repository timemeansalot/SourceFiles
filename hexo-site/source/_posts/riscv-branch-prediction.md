---
title: riscv-branch-prediction
date: 2023-03-13 16:15:33
tags: RISCV
---

<!--more-->

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

   - maybe increase clock period <- NO, longest clock time is the EXE stage
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

# Different branch predictor and the result CPI

> accurate branch predictor -> reduce misprediction -> reduce flush -> reduce CPI

## Static predictor

### always not token

### backward branch taken, forward branch not taken

## Dynamic predictor

### one bit predictor

### two bit predictor

1. Oscillator of one bit predictor

## More advanced dynamic predictor

# Open source project predictor and their CPI

## nutshell
## xs
## E203
## Alibaba C910
## Arm M55
## Arm A76
