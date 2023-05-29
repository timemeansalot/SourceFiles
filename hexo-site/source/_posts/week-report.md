[TOC]

# 带压缩指令时取指部分设计

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

   ![sbp taken, alu not taken](/Users/fujie/Pictures/typora/IF/sbtTaluN.svg)

## 方案 1

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

## 方案 2

**核心思想**：在方案 1 的基础上，将 32bits 的 SRAM 拆分成 2 块 16bits 的 SRAM，这样取指的粒度从 4B 变成了 2B

![](/Users/fujie/Pictures/typora/IF/method2.svg)

1. 整数指令对齐：利用 2 back SRAM 来处理非对齐地址，取指的时候，根据 addr 是否 4B 对齐，分为两种情况
   1. addr 是 4B 对齐：`instr={Left[addr>>2], Right[addr>>2]}`, 如图 pc==8 的情况
   2. addr 是 2B 对齐：`instr={Left[Right[addr>>2+1], Left[addr>>2]}`，如图 pc==2 的情况
      ![](/Users/fujie/Pictures/typora/IF/method2Sram.svg)
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

## 方案 3

**核心思想**：在方案 2 的基础上，将取出的指令 instr 放到 FIFO 中，节约`C+C`类型指令存储的访问 SRAM

> Q: 是否 4\*16 的 FIFO 也能保证没有 overflow?

![](/Users/fujie/Pictures/typora/IF/method3.svg)

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

## 三种方案对比

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

## 取指时可能更新的 PC 值

![redirectionSrc](/Users/fujie/Pictures/typora/IF/redirectionSrc.svg)

IF Stage 可能的取指地址有如下一些情况，其优先级：`TOP > EXE > ID > IF`

1. TOP: reset_addr 可以由 TOP 传给 IF Stage，也可以在 IF Stage 里默认一个 reset_addr
2. IF Stage: pc_register 的输出
3. ID Stage: SBP 判断跳转发生时，对应的跳转地址
4. EXE Stage:

   - ALU 判断 SBP 预测错误时，需要给出 redirection_pc
   - CSR

     1. mret 指令，需要将 epc 的地址作为下一条指令的地址
     2. 非法指令，需要跳转到 trap_vector 地址
     3. 外部中断发生时，需要跳转到 trap_vector 地址
     4. debug 发生时，需要跳到 debug 对应地址

     > PS: 根据 CSR 设计不同，上述四个 addr 可能会存在相同的情况

# 访存级 Load/Store 指令设计

## 信号定义

1. 输入到 D-Memory 的信号

   | 信号                  | 描述                  |
   | --------------------- | --------------------- |
   | dmem_addr[31:0]       | D-Memory 访存地址     |
   | dmem_write_data[31:0] | D-Memory 写入的数据   |
   | dmem_write_mask[3:0]  | D-Memory 写入时的掩码 |
   | dmem_rw               | 读写选择，0:读，1:写  |
   | valid/ready           | 握手信号              |

_如果指令不需要访问 D-Memory，可以令 RW=1, dmem_write_mask=0000_

> Q: D-Memory 是否需要 reset 信号？有一些项目里有这个信号、有些项目里没有

2. 来自 D-Memory 的信号

   1. dmem_read_data[31:0]: data read from D-Memory, this data may need be future modified
   2. valid/ready: valid when memory is ready to get address and contorl,
      ready when memory response data is ready
   3. error: memory access error

   | 信号                 | 描述                 |
   | -------------------- | -------------------- |
   | dmem_read_data[31:0] | D-Memory 读出的数据  |
   | valid/ready          | 握手信号             |
   | error                | 访存失败时的反馈信号 |

> 访存失败的时候，需要告知 EXE Stage 的 CSR 进入访存失败的异常处理程序

**由于当前设计的 D-Memory 只是 MEM Stage 的一块内存，因此 valid, ready, error 信号都没有启用**

3. 来自 EXE Stage 的流水线输入

   | 信号                   | 描述                                           |
   | ---------------------- | ---------------------------------------------- |
   | rs1_e_i[31:0]          | D-Memory 的写入数据(wire)                      |
   | dmem_type_e_i[3:0]     | D-Memory 的访存类型(wire)                      |
   | alu_result_e_i[31:0]   | ALU 计算的结果(wire)                           |
   | extended_imm_e_i[31:0] | 拓展为 32bits 的立即数部分，LUI 指令的写回数据 |
   | pc_plus4_e_i[31:0]     | pc+4 的数据，JAL, JALR 指令的写回数据          |
   | result_src_e_i[1:0]    | 寄存器写回数据来源选择信号                     |
   | rd_idx_e_i[4:0]        | 被写回的寄存器的下标                           |
   | reg_write_en_e_i       | 寄存器写回使能                                 |

   **由于 D-Memory 访存有一个 cycle 延迟，所以 alu_result_e_i, dmem_type_e_i 都是 wire 类型**

4. 到 WB stage 的流水线输出

   | 信号                      | 描述                                                 |
   | ------------------------- | ---------------------------------------------------- |
   | alu_result_m_o[31:0]      | ALU 计算的结果(wire), alu_result_e_i 寄存 2 拍的结果 |
   | extended_imm_m_o[31:0]    | 拓展为 32bits 的立即数部分，LUI 指令的写回数据       |
   | pc_plus4_m_o[31:0]        | pc+4 的数据，JAL, JALR 指令的写回数据                |
   | 🌟mem_read_data_m_o[31:0] | 从 D-Memory 中读出的数据，Load 指令的写回数据        |
   | result_src_m_o[1:0]       | 寄存器写回数据来源选择信号                           |
   | rd_idx_m_o[4:0]           | 被写回的寄存器的下标                                 |
   | reg_write_en_m_o          | 寄存器写回使能                                       |

   **alu_result_e_i 作为写回数据的时候，需要多暂存一拍以跟其他写回信号同步**

## 访存逻辑

本部分主要介绍 Load/Store 指令在 MEM Stage 具体的实现逻辑。

> 由于 CSR 模块放到 MEM Stage 会导致流水线刷新逻辑涉及到更多一个 Stage，导致刷新逻辑变得复杂，
> 因此考虑将 CSR 模块放到 EXE Stage，并且在 EXE Stage 对访存指令地址不对齐的情况触发 exception

1. LB, LBU, SB 指令由于其操作的是 1B 的数据，因此不会出现 address misaligned exception
2. LH, LHU, SH 指令，`addr[0]!=0`时，会出现 address misaligned exception
3. LW, SW 指令，`addr[1:0]!=00`时，会出现 address misaligned exception

### Load 指令

1.  涉及到的指令：`LB, LBU, LH, LHU, LW`
2.  D-Memory 写入地址：dmem_addr = alu_result_e_i;
3.  读写类型：dmem_rw = 1'b0;
4.  从 D-Memory 读出的数据 `dmem_read_data` 跟输出到 WB Stage 数据 `mem_read_data_m_o` 的关系

    > 根据 Load 指令的类型及访存地址最后两位的地址，扩展 D-Memory 的输出数据，如下表所示：

    | mem_read_data_m_o                                   | mem_type | addr[1:0] |
    | --------------------------------------------------- | -------- | --------- |
    | `{{24{dmem_read_data[7]}}, dmem_read_data[7:0]}`    | MEM_LB   | 00        |
    | `{{24{dmem_read_data[15]}},dmem_read_data[15:8]}`   | MEM_LB   | 01        |
    | `{{24{dmem_read_data[23]}},dmem_read_data[23:16]}`  | MEM_LB   | 10        |
    | `{{24{dmem_read_data[31]}},dmem_read_data[31:24]}`  | MEM_LB   | 11        |
    | `{{24{1'b0} ,dmem_read_data[7:0]}`                  | MEM_LBU  | 00        |
    | `{{24{1'b0} ,dmem_read_data[15:8]}`                 | MEM_LBU  | 01        |
    | `{{24{1'b0} ,dmem_read_data[23:16]}`                | MEM_LBU  | 10        |
    | `{{24{1'b0} ,dmem_read_data[31:24]}`                | MEM_LBU  | 11        |
    | `{{16{dmem_read_data[15]}}, dmem_read_data[15: 0]}` | MEM_LH   | 00        |
    | `{{16{dmem_read_data[31]}}, dmem_read_data[31:16]}` | MEM_LH   | 10        |
    | `{{16{1'b0}, dmem_read_data[15:0]}`                 | MEM_LHU  | 00        |
    | `{{16{1'b0}, dmem_read_data[31:16]}`                | MEM_LHU  | 10        |
    | dmem_read_data                                      | MEM_LW   | 00        |

### Store 指令

1. 涉及到的指令：`SB, SH, SW`
2. D-Memory 写入地址：dmem_addr = alu_result_e_i;
3. 读写类型：dmem_rw = 1'b1;
4. 写入掩码: dmem_write_mask

   > 写入掩码主要根据 Load 指令类型和访存地址，来控制写入到 D-Memory 的哪些 byte。
   > D-Memory 需要支持掩码操作。

   | dmem_write_mask | mem_type        | addr[1:0] |
   | --------------- | --------------- | --------- |
   | 0001            | MEM_SB, MEM_SBU | 00        |
   | 0010            | MEM_SB, MEM_SBU | 01        |
   | 0100            | MEM_SB, MEM_SBU | 10        |
   | 1000            | MEM_SB, MEM_SBU | 11        |
   | 0011            | MEM_SH, MEM_SHU | 0x        |
   | 1100            | MEM_SH, MEM_SHU | 1x        |
   | 1111            | MEM_SW          | xx        |

5. 写入到 D-Memory 的数据：dmem_write_data

   `dmem_write_data[31:0]`是写入到 D-Memory 中的数据, `rs1_e_i` 是 EXE Stage 输入的代写入到 D-Memory 的数据

   | dmem_write_data                         | mem_type | addr[1:0] |
   | --------------------------------------- | -------- | --------- |
   | `{{24{1'b0}}, rs1_e_i[7:0]}`            | MEM_SB   | 00        |
   | `{{16{1'b0}}, rs1_e_i[7:0], {8{1'b0}}}` | MEM_SB   | 01        |
   | `{{8{1'b0}}, rs1_e_i[7:0], {16{1'b0}}}` | MEM_SB   | 10        |
   | `{rs1_e_i[7:0], {24{1'b0}}}`            | MEM_SB   | 11        |
   | `{{16{1'b0}}, rs1_e_i[15:0]}`           | MEM_SH   | 0x        |
   | `{rs1_e_i[15:0], {16{1'b0}}}`           | MEM_SH   | 1x        |
   | rs1_e_i                                 | MEM_SW   | xx        |

### 非访存指令

1. 读写类型：dmem_rw = 1'b1;
2. 写入掩码: dmem_write_mask=4'b0000;

# riscv-tests 环境搭建

1. 验证目录

   ```bash
    src
    ├── rtl
    │   ├── top.v
    │   ├── ...
    │   ├── ...
    │   ├── top_tb.v
    └── verification
        ├── Makefile
        ├── asm
        └── rtl
   ```

   1. 目前所有的源文件都在项目的`src`文件下
   2. `src/rtl`存档 MCU 的 verilog 代码
   3. `src/verification`是使用 riscv-tests 对 rtl 代码进行验证的目录
      1. `asm`：存放所有的 riscv-tests 的汇编测试文件
      2. `rtl`：存放所有的带测试的 verilog 源文件
      3. `Makefile`：存放所有验证时需要的一些命令，如“编译 verilog”、“编译汇编文件”、“仿真”等

2. Makefile 内容

   ```Makefile
   .DEFAULT_GOAL := wave
   # compile asm source file to get test cases for MCU
   asmCode:
   	@(cd asm && ./clean.sh && ./regen.sh && cd ..)
   # copy source file before compile
   copy:
   	@(rm -rf rtl/*.v && cp ../rtl/*.v rtl)
   # simulate DUT, you'd better `make asmCode` first to generated machine code
   sim:
   	@(cd rtl && make sim)
   # show waveform
   wave:
   	@(cd rtl && make waveform)

   # regression test
   # TODO: implement in the future.
   # Because MCU can't pass even one test file in riscv-tests now!
   # So we don't need to test the whole riscv-tests now.
   clean:
   	@(cd asm && ./clean.sh && cd ../rtl/ && make clean)
   # declare phone target
   PHONY: clean wave sim copy asmCode
   ```

   1. asmCode: 会进入到 asm 文件夹，并且调用脚本`regen.sh`编译所有的 riscv-tests 文件，并且得到机器码;  
      testbench 会从得到的机器码文件中，加载指令到 I-Memory 中
   2. copy：用`src/rtl`下复制所有的`.v`文件替换`verification/rtl`目录下的所有`.v`文件
   3. sim：会进入`verification/rtl`目录下，并且使用 make sim 命令，
      该命令会编译 rtl 文件，再执行 rtl 仿真
   4. wave：使用 gtkWave 查看仿真生成的波形
   5. regression test: 使用所有的 riscv-tests 测试用例测试 MCU，
      如果都通过了则说明 MCU 通过了 riscv-tests 测试;  
      但是现在的 MCU 一个测试都无法通过，所以目前暂时不支持 regression test.

3. 仿真结果
   riscv-tests 汇编文件，默认测试通过的时候，x3 的值为 1，所以每一轮仿真结束之后，我们在 testbench 里检查
   x3 的值就可以判断测试是否通过

   ![sim fail](https://s2.loli.net/2023/05/25/TcrkZPS9DbLeV8h.png)
