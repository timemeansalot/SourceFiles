[TOC]

## 访存级 Load/Store 指令设计

### 信号定义

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

### 访存逻辑

本部分主要介绍 Load/Store 指令在 MEM Stage 具体的实现逻辑。

> 由于 CSR 模块放到 MEM Stage 会导致流水线刷新逻辑涉及到更多一个 Stage，导致刷新逻辑变得复杂，
> 因此考虑将 CSR 模块放到 EXE Stage，并且在 EXE Stage 对访存指令地址不对齐的情况触发 exception

1. LB, LBU, SB 指令由于其操作的是 1B 的数据，因此不会出现 address misaligned exception
2. LH, LHU, SH 指令，`addr[0]!=0`时，会出现 address misaligned exception
3. LW, SW 指令，`addr[1:0]!=00`时，会出现 address misaligned exception

#### Load 指令

1.  涉及到的指令：`LB, LBU, LH, LHU, LW`
2.  D-Memory 写入地址：dmem_addr = alu_result_e_i;
3.  读写类型：dmem_rw = 1'b0;
4.  从 D-Memory 读出的数据 `dmem_read_data` 跟输出到 WB Stage 数据 `mem_read_data_m_o` 的关系

    > 根据 Load 指令的类型及访存地址最后两位的地址，扩展 D-Memory 的输出数据，如下表所示：

    | mem_read_data_m_o                                 | mem_type | addr[1:0] |
    | ------------------------------------------------- | -------- | --------- |
    | {{24{dmem_read_data[ 7]}}, dmem_read_data[7:0]}   | MEM_LB   | 00        |
    | {{24{dmem_read_data[15]}},dmem_read_data[15:8]}   | MEM_LB   | 01        |
    | {{24{dmem_read_data[23]}},dmem_read_data[23:16]}  | MEM_LB   | 10        |
    | {{24{dmem_read_data[31]}},dmem_read_data[31:24]}  | MEM_LB   | 11        |
    | {{24{1'b0} ,dmem_read_data[7: 0]}                 | MEM_LBU  | 00        |
    | {{24{1'b0} ,dmem_read_data[15:8]}                 | MEM_LBU  | 01        |
    | {{24{1'b0} ,dmem_read_data[23:16]}                | MEM_LBU  | 10        |
    | {{24{1'b0} ,dmem_read_data[31:24]}                | MEM_LBU  | 11        |
    | {{16{dmem_read_data[15]}}, dmem_read_data[15: 0]} | MEM_LH   | 00        |
    | {{16{dmem_read_data[31]}}, dmem_read_data[31:16]} | MEM_LH   | 10        |
    | {{16{1'b0}, dmem_read_data[15: 0]}                | MEM_LHU  | 00        |
    | {{16{1'b0}, dmem_read_data[31:16]}                | MEM_LHU  | 10        |
    | dmem_read_data                                    | MEM_LW   | 00        |

#### Store 指令

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

   | dmem_write_data                           | mem_type | addr[1:0] |
   | ----------------------------------------- | -------- | --------- |
   | { {24{1'b0}}, rs1_e_i[7:0] };             | MEM_SB   | 00        |
   | { {16{1'b0}}, rs1_e_i[7:0], { 8{1'b0}} }; | MEM_SB   | 01        |
   | { {8{1'b0}}, rs1_e_i[7:0], {16{1'b0}} };  | MEM_SB   | 10        |
   | { rs1_e_i[7:0], {24{1'b0}} };             | MEM_SB   | 11        |
   | { {16{1'b0}}, rs1_e_i[15:0] };            | MEM_SH   | 0x        |
   | { rs1_e_i[15:0], {16{1'b0}} };            | MEM_SH   | 1x        |
   | rs1_e_i                                   | MEM_SW   | xx        |

#### 非访存指令

1. 读写类型：dmem_rw = 1'b1;
2. 写入掩码: dmem_write_mask=4'b0000;
