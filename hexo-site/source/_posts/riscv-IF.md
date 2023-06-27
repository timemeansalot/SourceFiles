---
title: RISC-V 5级流水线取指级设计
date: 2023-03-27 10:57:57
tags: RISC-V
---

RISCV 5 级流水线“取指”部分设计

1. 开源项目中“取指级”参考
2. 本项目“取指级”设计
<!--more-->

[TOC]

> 取指级需要处理的 2 个关键问题：1. PC 重定向 2. 指令对齐

## 开源项目取指参考

### 果壳

![image-20230627130147655](https://s2.loli.net/2023/06/27/cVzHaL2BuUrMJQv.png)

1. 取指

   > 功能: 取指、更新 PC、指令对齐

   1. 根据 BP 的结果更新 PC
   2. 根据 PC 从`I$`中取数据，一次取 1 个 Cache Line(64bits 的数据
   3. 取指数据会被压入到指令对齐缓冲`IAB`，由 IAB 识别指令边界，得到指令

2. 分支预测器

   > 功能：三种类型的混合预测器

   1. 默认 PC+8
   2. BTB：512 entry，每个 entry 的数据如下图所示： -> JAL, JALR
      ![image-20230627130221058](https://s2.loli.net/2023/06/27/pP3GTXNriet15Ec.png)
   3. RAS：16 entry, 每个 entry 是 32bit 的 PC 地址 -> call, ret
   4. PHT: 512entry，每个 entry 是 2bit 预测器-> 处理条件分支指令(B-Type Instructions)

   > RAS 和 PHT 用<u>同步写异步读的寄存器</u>来实现, BTB 由于面积较大而通过<u>快速 SRAM</u> 来实现, 因此在访问前者时需要将取指 PC 缓存一拍.

3. CSR

   > 功能：判断 trap 发生、类型，传递给 WB

   1. CSR 单元处于 EXE 级，配合 CSR Register 实现权限控制及对 trap 处理
   2. Load Store 指令由 LSU 判断是否发生 exception，如果发生则由 LSU 将 excption 信息转发给 CSR 单元  
      果壳项目中：<u>EXE 级和 MEM 级被合并成了同一个</u>, EXE 后面直接跟的是 WB, 其 EXE 可能占用多个周期
   3. 其他指令在 decode 阶段就可以判断其 exception，exception 信息由 ID 经过流水线传递给 CSR 单元

4. WB

   > 功能：**传递重定向 PC** 及写回数据(writ bank data)

   1. 重定向(redirection)：当 EXE 发现 BP 错误、CSR 判断 trap 发生的时候，触发重定向 -> 发送正确的 PC 给 IF
   2. 写回：将需要写回给 rd 的数据传回给 ISU，由 ISU 写入到 Register File

### 蜂鸟低功耗处理器核

![e203 storage system](https://s2.loli.net/2023/04/06/EIQD1LbWTl7OvGy.png)

1. 采用 ITCM

   - 蜂鸟采用 64bits 的 SRAM 作为 ITCM
   - 面积更加紧凑、顺序读取 64bits 的数据，其只需要 1 次动态功耗

   ![ITCM](https://s2.loli.net/2023/04/06/SKnDXtylg2pUuso.png)

2. 指令对齐:

   - leftover buffer,  
     蜂鸟采用 leftover buffer 来实现指令对齐，存储指令的高 16bits 到 leftover buffer：连续取指的时候，1 个 cycle 可以解决指令不对齐问题；非连续取指的时候，必须 2 个 cycle 才可以解决指令不对齐问题
     ![image-20230627130320584](https://s2.loli.net/2023/06/27/E5l3Lv1VtTP4cwI.png)
   - 2 bank SRAM

     ![image-20230627130610648](https://s2.loli.net/2023/06/27/D5VAzyJ6pO49sd7.png)

3. 蜂鸟支持 C 压缩指令集，因此它需要考虑指令对齐的问题(16bit 和 32bit 的指令混合存储在 I-memory 中)
   - RISCV 指令格式：32bit 的指令，其低 2bit 一定是 11；否则是 16bit 的指令
   - 如果只支持 32bits 的指令，则可以默认取指地址低 2bit 为 00（默认指令恒 4B 对齐）
4. 蜂鸟 EXE 级在遇到<u>分支预测错误、trap</u>的时候，都会触发重定向，会返回给 IF
   ![image-20230627130908630](https://s2.loli.net/2023/06/27/SiUlO7ZA83y2D5p.png)

   - BP 错误：条件跳转指令的结果由 EXE 级的 ALU 计算得到
   - CSR: 蜂鸟只支持机器模式、没有虚拟地址不存在 page 缺失相关的异常

   > 中断和异常的实现时处理器实现非常关键的一部分，同时也是最为烦琐的一部分。得益 于 RISC-V 架构对于中断和异常机制的简单定义，蜂鸟 E200 对其进行硬件实现的代价很小。 即便如此，异常和中断相关的源代码相比其他模块而言，仍然非常细琐繁杂

## 不带压缩指令时取指部分设计

> 取指阶段主要需要解决的问题是：<u>PC 重定向、指令对齐</u>

1. PC -> I-Memory -> Instruction: 一共有 2 个 cycle 的 delay，需要保证 PC 和 instruction 在流水线上是匹配的，在代码里使用了一个额外的`pc_delay`寄存器来提供额外一个 cycle 的 PC 延迟
   ![image-20230627131000094](https://s2.loli.net/2023/06/27/hsogZdXDfIykOTw.png)

2. 当流水线刷新之后，新地址对应的指令在 2 个 cycle 之后送到 ID Stage ，因此其后续两个 cycle 的指令都是无效指令，看作 2 条 nop 指令

3. EXE 如果和 ID 同时发来了重定向信号，则 EXE 的信号优先级更高：因为 EXE 的指令更老

   ```verilog
   // pipelineIF.v
   assign pc_mux = (taken_e_i == 1'b1) ? redirection_e_i:
     							(taken_d_i == 1'b1) ? redirection_d_i : pc_register;
   ```


### PC 重定向

1. IF 没有分支预测，PC+=2  
   <u>IF 阶段设置有一个 FIFO，最多存储 5\*16bits 的数据</u>，该 FIFO 的设置是因为我们不知道指令是 16bits 的还是 32bits 的。

   **重定向发生的时候，I-Mem 直接采用重定向的 PC 作为取值地址**，可以避免 1 个 cycle 的 penalty
   重定向的 PC 有如下可能的原因：

   1. 系统初始化 reset 的时候，需要更新 PC 为初始化地址
   2. 顺序 PC
   3. ID 阶段的静态分支预测，需要发送预测的 PC 和跳转信号到 IF
   4. EXE 阶段若判断 ID 的分支预测错误，需要发送正确的 PC 和跳转信号到 IF
   5. MEM 阶段当异常和中断发生的时候，需要 CSR 单元发送 对应的地址 和跳转信号到 IF
      - illegal_addr, interrupt_addr, debug_addr
      - 此外，对于`mret`指令，MEM 阶段需要从 CSR 寄存器中返回 EPC 的值到 IF

   **在引入 MEM 阶段的重定向信息之前，只有 ID，EXE 会导致 IF 的 PC 重定向；引入 MEM 的重定向之后，对应的 pipeline 冲刷逻辑，都变得更加复杂**

2. ID 采用静态分支预测，如果解码判断是分支指令，会计算 target PC  
   不会冲刷流水线
   ![image-20230627131128707](https://s2.loli.net/2023/06/27/B5KJ7oQVm4SY3a6.png)
3. EXE 的 ALU 会对条件分支指令的结果进行判断，如果 ID 判断错误，EXE 会产生重定向 PC  
   冲刷 1 条流水线
   ![image-20230627131140165](https://s2.loli.net/2023/06/27/EUNcdCjw3Q12Mgh.png)
4. MEM 的 CSR 单元会判断 trap 是否发生，如果发生 EXE 也会产生重定向 PC  
   冲刷 2 条流水线
   ![image-20230627131150989](https://s2.loli.net/2023/06/27/zmbJUyurotLqQiN.png)

### 指令对齐

ITCM 占 64kB

1. FIFO 工作原理

   - FIFO 每次从 I-memory 读取 2x16 的数据
   - FIFO 中数据少于等于 3 的时候，FIFO 会从 I-memory 中读取数据，避免 underflow
   - FIFO 中数据大于 3 的时候，FIFO 会停止从 I-memory 中读取数据，避免 overflow
   - 当 ID 发现指令是 32bits 的时候，FIFO 头部 2 条数据会被 POP，FIFO 数据量-2
   - 当 ID 发现指令是 16bits 的时候，FIFO 头部 1 条数据会被 POP，FIFO 数据量-1

2. 采用 2 bank SRAM 作为 I-Memory, 两个 bank 的 SRAM 都是 16bits 的位宽，配合 FIFO 可以处理 32bits 指令不对齐的情况, 其工作原理如下：

   - 顺序读取: 顺序读取的时候不存在 PC 重定向，FIFO 不需要刷新

     1. 连续读 16bits 的指令：每次消耗 FIFO 中 1 条数据，读入 2 条数据到 FIFO，FIFO 数据量会逐步增加，当大于等于 3 的时候，FIFO 就不会继续从 I-memory 读取数据了
     2. 连续读 32bits 的指令：每次消耗 FIFO 中 2 条数据，读入 2 条数据到 FIFO，FIFO 数据量会保持恒定，FIFO 会继续从 I-memory 读取数据了
     3. 混合读取 16bits 和 32bits 的数据：上述两种方式的混合

   - PC 重定定向: 当发生 PC 重定向之后，FIFO 中现存的所有数据都是无效的，需要被刷新，并且下一个周期从 I-memory 中读出的指令也是无效的指令，也需要被丢弃; 在第二个周期读出的指令是重定向 PC 对应的指令，会被 PUSH 到 FIFO 中

> PS: 在只支持 32bits 指令的处理器中，JALR 指令可能会计算得到的 PC 不是 4B 对齐的，但是在模拟器中测试该场景的时候，模拟器默认忽略了 PC 最低 2bits，导致不对齐的 PC 也可以从 I-memory 中读取指令，没有触发 exception.

## References

1. [Nutshell Documents](https://oscpu.github.io/NutShell-doc/%E6%B5%81%E6%B0%B4%E7%BA%BF/ifu.html)
2. [riscv-mcu/e203_hbirdv2](https://github.com/riscv-mcu/e203_hbirdv2)

## 带压缩指令时取指部分设计

- [x] TODO: new pc source, refer to the essay
- [x] TODO：new instruction pc must by used by EXE stage when revise SBP decision,
      sbp taken, alu not taken<-need the third instruction after current instruction
      method 1: pass pc+2 and pc+4(more register),
      method 2: pass pc to exe and calculate pc+4 or pc+2 in exe(more calculation)
- [x] TODO: new diagram of IF with compressed instruction: 2 SRAM bank, FIFO, new pc logic
- [x] TODO: with 2 bank SRAM, how to initiate data into SRAM? In testbench, write to 1 bank SRAM, then fill
      the two SRAM by the SRAM in testbench.
- [x] TODO: pc increment logic when find compress instruction
- [x] TODO: pc_plus4 change into pc_next, because we next pc could be pc+2
- [x] TODO: add a summary of how each method solve the above key problem

**支持压缩指令时，IF Stage 设计需要考虑的要点**：

1. 当压缩指令跟整数指令混合存放的时候，如何处理整数指令取指问题？
   > 由于 RISC-V 在支持压缩指令的情况下，16bits 的压缩指令跟 32bits 的整数指令，是混合存储的，
   > 因此整数指令可能不是按照 4B 对齐的，微架构需要对整数指令不对齐的情况做处理。
2. 存在压缩指令的时候，如何将 ID Stage 的指令跟指令对应的 PC 相匹配?
   > 因为 SBP 计算 redirection_pc 的时候，需要用到 pc
   > pc 其实是建立的对压缩、整数指令的判断的基础上的
3. 存在压缩指令的时候，IF 顺序取指的时候如何增加 pc?
   > 取到压缩指令的时候，pc+=2；取到整数指令的时候 pc+=4
4. SBP 预测跳转，ALU 验证不跳转的时候，EXE 如何获得正确的 `pc_next_next` 发送给 IF？

   1. ID Stage 的 SBP 预测跳转时，会将 IF 的取指地址修改为 prediction_addr
   2. EXE Stage 的 ALU 如果判断不跳转，需要将 IF 的取指地址更改为 pc_next_next,
      并且冲刷到 prediction_addr 取出的指令

   ![image-20230627131305174](https://s2.loli.net/2023/06/27/Ob1fdTnopXZYVmF.png)

### 方案 1

**核心思想**：采用 32 位宽的 SRAM，每次取指 4B 的数据，采用 leftover buffer 存储上次取指的高 16bits，用于判断指令是否是压缩指令、完成 32bits 指令的拼接

> 参考了蜂鸟的设计、以及论文《用于计量的嵌入式 RISC-V 处理器设计及 MCU 实现》

![压缩指令与整数指令存储组合](https://s2.loli.net/2023/05/23/OSDrPmAwNLc5iF7.png)
![压缩指令译码器指令判别流程图](https://s2.loli.net/2023/05/23/XS4AhVs71Wmwl6r.png)

1. leftover buffer 的作用：

   1. 存储 32bits 指令的低 16bits 数据
   2. 判断压缩指令和整数指令的标志

2. 该方案的优点：顺序取指的时候，PC+=4 即可; 取指单位 4B，PC 最后两位取指的时候直接当`00`来处理
3. 该方案的缺点：
   1. 压缩指令跟整数指令的组合一共有 5 种，每次取 4B 数据之后，都需要经过复杂的判断才可以判断出指令的种类
   2. 32bits 指令不对齐的情况下，需要跟 leftover buffer 中的数据拼接才可以得到真正的整数指令
   3. 将指令与其对应的 pc 对应不方便（因为指令可能不是直接按照 pc 从 SRAM 中取出来的，而是跟 leftover buffer 拼接而成的）
   4. 地址重定向发生的时候，如果重定向地址不是 4B 对齐的，需要 2 次访问 SRAM 才可以拼成一个整数指令

### 方案 2

**核心思想**：在方案 1 的基础上，将 32bits 的 SRAM 拆分成 2 块 16bits 的 SRAM，这样取指的粒度从 4B 变成了 2B

![image-20230627131329377](https://s2.loli.net/2023/06/27/3YviMgsdQ8Zx1fH.png)

1. 整数指令对齐：利用 2 back SRAM 来处理非对齐地址，取指的时候，根据 addr 是否 4B 对齐，分为两种情况
   1. addr 是 4B 对齐：`instr={Left[addr>>2], Right[addr>>2]}`, 如图 pc==8 的情况
   2. addr 是 2B 对齐：`instr={Left[Right[addr>>2+1], Left[addr>>2]}`，如图 pc==2 的情况
      ![image-20230627131344666](https://s2.loli.net/2023/06/27/K3c12ZuPn7vH9JX.png)
2. 压缩指令判断，由于不存在 leftover buffer，判断压缩指令与整数指令，只需要看 instr[1:0]即可,
   上图中红色部分就是在 ID 阶段通过比较指令最低 2bits 来判断指令是否是压缩指令

   1. `instr[1:0]==11`: pc+=4
   2. `instr[1:0]!=11`: pc+=2

   取出的指令`instr`可能的情况一共有 3 种：`I`, `C+C`, `I+C`,
   针对 `C+C` 的情况，当作 `I+C` 处理，以简化流水线冲刷的逻辑(代价是 `C+C` 本可以只访问一次 SRAM 的)。

   > 32bits 的压缩指令，不管是`C+C`还是`I+C`，送到 ID 的 extending unit(EU)之后，EU 都会将其低 16bits 压缩指令部分扩展成对应的 32bits 整数指令

3. 如何匹配每条指令和对应的 pc:  
   在 IF Stage 取指的时候，每条指令都是按照 pc_sel 取指的，因此每条指令都对应 pc_sel 的值
4. pc_next_next 如何计算：
   由于压缩指令、整数指令混合存储，因此 pc_next_next 的值依赖于当前指令以及后续那条指令的类型，
   假设指令序列为 3->2->1，令指令 1 对应的地址为 pc

   1. 计算 pc_next:
      - 指令 1 是压缩指令：pc_next=pc+2
      - 指令 1 不是压缩指令：pc_next=pc+4
   2. 计算 pc_next_next:
      - 指令 2 是压缩指令：pc_next_next=pc_next+2
      - 指令 2 不是压缩指令：pc_next_next=pc_next+4

5. 该方案的优点：
   1. 没有 leftover buffer，压缩指令判读变得简单、32bits 指令也不需要拼接
   2. 将指令跟 PC 对应很简单，指令对应的 PC 一定是 pc_sel
   3. 地址重定向发生的时候，即使 PC 不是 4B 对齐，也可以一个 cycle 就从 SRAM 中取出指令
6. 该方案的缺点：
   1. IF 阶段计算 pc_next 的逻辑依赖于**对取出的指令的判断**，从而判断 pc_next 等于 pc+4 还是 pc+2
   2. 两个相邻的压缩指令(`C+C`类型)，明明可以访问 1 次 SRAM，但是却需要访问 2 次

### 方案 3

**核心思想**：在方案 2 的基础上，将取出的指令 instr 放到 FIFO 中，节约`C+C`类型指令存储的访问 SRAM

> Q: 是否 4\*16 的 FIFO 也能保证没有 overflow?

![image-20230627131400942](https://s2.loli.net/2023/06/27/JaVN9chLMnCQklm.png)

1. 整数指令对齐：取指逻辑跟方案 2 相同，差别在于：
   1. 取出的指令放到 FIFO 中，而不是放到 IF/ID pipeline register 中
   2. FIFO 没有空间的时候，不会从 I-Memory 中取指令放到 FIFO 中
2. FIFO 逻辑(Question -> FIFO 容量为 4 能否满足需求？)
   1. 避免 underflow：由于 ID 一次最多取走 32bits 的数据，因此 FIFO $count \le 2$ 的时候，FIFO 允许写入
   2. 避免 overflow：若令 FIFO 总容量为 4，则 FIFO $count\ge3$ 时，FIFO 不能写入
3. 压缩指令判断：从 FIFO 头部取出 32bits 的指令送到 ID，有 ID Stage 比较指令最低 2bits 来判断是否是压缩指令
   1. 如果是压缩指令，则 FIFO 将头部 16bits 指令 pop，FIFO 容量-1
   2. 如果是整数指令，则 FIFO 将头部 32bits 指令 pop，FIFO 容量-2
4. 如何匹配每条指令和对应的 pc:
   1. 方案 3 中，取指的 pc 跟每条指令的 pc 不是一一对应关系，取指 pc 只负责在 FIFO 有空间的时候，
      顺序的取指放入到 FIFO 中
   2. 方案 3 中每条指令对应的 PC 在 ID Stage 中维护，ID Stage 只会在 reset 或者重定向发生的时候，
      才会从 IF 得到 pc
5. pc_next_next 如何计算？跟方案 2 不同处有：
   1. 方案 3 在 ID Stage 再判断是否是压缩指令，所以 pc_next 在 ID Stage 计算得到
   2. pc_next_next 在 EXE Stage 计算得到
6. 该方案的优点：
   1. 取指的 pc 不需要判断指令是否是压缩指令，默认+4 即可
   2. 针对`C+C`类型的指令，只用访问 SRAM 一次
7. 该方案的缺点：
   1. 指令跟取指 pc 对应逻辑比较复杂
   2. 相比于方案 2，计算 pc_next_next 需要额外在 EXE Stage 多引入一个加法器
   3. IF Stage 引入了 FIFO，增加了复杂度

### 三种方案对比

1. 方案 1 的设计是最简单的，其明显的缺点在于：
   1. 压缩指令跟整数指令的组合复杂，因此判断逻辑也很复杂
   2. 重定向发生的时候，如果 redirection_pc 不是 4B 对齐的，需要 2 次访存才可以取到整数指令
2. 方案 2 在方案 1 的基础上将 1 bank sram 改进为 2 bank sram
   1. 解决了方案 1 中明显的缺点
   2. 仍然存在的问题在于：取指 pc 的计算，需要判断从 I-Memory 中取出的指令是否是压缩指令
3. 方案 3 在方案 2 的基础上，引入了 FIFO，并且将压缩指令的判断推迟到了 ID Stage
   1. 取指 pc 不用依赖于指令的类型
   2. 付出的代价是
      1. FIFO 带来的复杂度
      2. 指令跟 pc 的对应关系，变得比方案 2 复杂
      3. 需要在 EXE 阶段增加额外的加法器来计算 pc_next_next

> 综上：如果暂时没有更好的解决方案，我们可以在方案 2、3 之间选择一个

### 取指时可能更新的 PC 值

![image-20230627131422562](https://s2.loli.net/2023/06/27/sVIvNR3qoMp9TPy.png)

IF Stage 可能的取指地址有如下一些情况，其优先级：`TOP > EXE > ID > IF`

1. TOP(reset_addr): 可以由 TOP 传给 IF Stage，也可以在 IF Stage 里默认一个 reset_addr
2. IF Stage(pc_register_addr): pc_register 的输出
3. ID Stage(prediction_addr): SBP 判断跳转发生时，对应的跳转地址
4. EXE Stage(redirection_addr):

   - ALU 判断 SBP 预测错误时，需要给出 redirection_pc_addr
   - CSR

     1. mret 指令，需要将 epc 的地址作为下一条指令的地址
     2. 非法指令，需要跳转到 trap_vector 地址
     3. 外部中断发生时，需要跳转到 trap_vector 地址
     4. debug 发生时，需要跳到 debug 对应地址

     > PS: 根据 CSR 设计不同，上述四个 addr 可能会存在相同的情况


![verification](https://s2.loli.net/2023/06/01/NrQDle4aohYsRmc.png)
测试的情况有：

- [x] 地址 4B 对齐，顺序取指
- [x] 地址非 4B 对齐，顺序取指
- [x] 地址重定向发生后两个周期，顺利取出指令到 IR(Instruction Register)
- [x] 顺序取指时：
  - [x] ID 读取压缩指令（16bits)
  - [x] ID 读取整数指令（32bits）
  - [x] 流水线 stall（0bits）
