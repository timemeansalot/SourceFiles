---
title: 付杰周报-20230923
date: 2023-03-08 14:45:34
tags: RISC-V
---

[TOC]

# 增加ecall测试用例

## 修改的部分

## 发现的问题

# 测试外部中断

# RISC-V 问题&解决方法

`hazard unit`计算`flush_d_i`的时候，没有考虑ecall指令，ecall指令在ID Stage发现之后，
其后续3条指令都是无效指令(因为ecall指令产生效果到`htrap_handler`产生trap信号，有3个周期)
![](https://s2.loli.net/2023/10/19/bT3RBCZKkFqW9AG.png)

- 目前的逻辑是：ID Stage译码到`ecall`指令之后，尝试修改`CSRs[8]`寄存器的值，然后`htrap_handler`
  会通过`CSRs[8]`寄存器的对应<u>software interrupt的位</u>来产生Trap信号发送到各个功能部件
  其核心逻辑在于**ID Stage已经检测到了ecall，但是还是需要htrap_handler来触发Trap信号**
