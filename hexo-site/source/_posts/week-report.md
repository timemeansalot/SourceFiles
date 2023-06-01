[TOC]

<!--more-->

# 压缩指令实现

![](/Users/fujie/Pictures/typora/IF/compress_with_pc.svg)

测试的情况有：

- [x] 地址 4B 对齐，顺序取指
- [x] 地址非 4B 对齐，顺序取指
- [x] 地址重定向发生后两个周期，顺利取出指令到 IR(Instruction Register)
- [x] 取指时：
  - [x] ID 读取压缩指令（16bits)
  - [x] ID 读取整数指令（32bits）
  - [x] 流水线 stall（0bits）

![verification](https://s2.loli.net/2023/06/01/NrQDle4aohYsRmc.png)

# MEM 级访存指令实现

测试的情况有：

- [x] LW, SW: 4B 对齐时写入和读出
- [x] SH, LH, LHU: 2B 对齐时写入、读出
- [x] SB, LB, LBU: 1B 对齐时写入、读出
- [x] SH, SB 带 mask 的写入

![simluation](https://s2.loli.net/2023/05/30/Y4i5UHZsV3umnOR.png)

# 流水线其余待修改部分

> 由于目前流水线正在测试 Hazard、Flush、Stall 等功能，因此各级流水线接口不宜修改,
> 待测试稳定之后，再修改各级流水线以支持压缩指令

为了支持压缩指令执行，流水线各级需要修改的地方有：

1. ID Stage
   - [ ] 根据指令长度，计算`pc_next=pc+4`或者`pc_next=pc+2`
   - [ ] 根据指令长度，返回`drain_cnt`给 IF Stage，IF Stage 需要根据`drain_cnt`决定
         FIFO pop 的长度
   - [ ] 增加`instru_pc`寄存器，用来匹配当前指令跟其对应的 pc
   - [ ] 增加`mux`用于处理重定向发生、reset 发生时，pc 的选择
2. EXE Stage
   - [ ] 增加`pc_next_next`的计算，在分支预测错误的时候返回给 ID
