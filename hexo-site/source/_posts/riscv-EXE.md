---
title: RISC-V执行级设计
date: 2023-04-04 15:38:11
tags: RISC-V
---

![ALU](https://s2.loli.net/2023/04/10/xW4djv3JGEB2zyg.png)
RISC-V 执行级设计

<!--more-->

# 32 Shifter Design

[Github 仓库地址](https://github.com/ChipDesign/FAST_INTR_CPU/tree/main/src/rtl)
![](https://s2.loli.net/2023/03/10/CtRza3lUdwKHB7y.png)

RV-32IM 需要实现的移位操作不包括循环移位，只包括：<u>逻辑左移</u>、<u>逻辑右移</u>和<u>算数右移</u>。  
若使用**移位寄存器**来实现移位，每个周期移位是固定的，因此需要多个周期才可以完成移位操作。
![shift01](https://s2.loli.net/2023/03/11/D6uWOnjrogmNsvk.png)
上图是一个由 4 个 D 触发器构成的简单向右移位寄存器，数据从移位寄存器的左端输入，每个触发器的内容在时钟的上升沿将数据传到下一个触发器。

在 ALU 种需要多数据进行多位移位的操作，采用移位寄存器一次只能移动移位，效率太低；**桶形移位器**采用组合逻辑的方式来实现同时移动多位，在效率上优势极大。因此桶形移位器常被用在于 ALU 中实现移位。

![barrlShifter](https://s2.loli.net/2023/03/11/wSgedMkjVhoq1A6.jpg)

1. din：待移位待输入数据
2. shift: 移位待位数，有效范围为$[0, \log N-1]$
3. Left/Right: 左移或者右移
4. Arith/Logic：算数右移/逻辑右移
5. dout：移位后的数据

以 4bits din 的 barrlShifter 为例，其 Schematic 如下：

![barrlShift4bits](https://s2.loli.net/2023/03/11/Wv3ZMVen9fEbXpY.jpg)

- 对于 Nbits 的输入数据，其需要的选择器一共有$\log N$层，每一层共有 N 个选择器，其中第一层选择是否移位 1bit，第二层选择是否移位 2bits，...。
- 对每一个 4 选 1 选择器，其 00 和 10 输入选择未移位后的数据；01 选择右移的数据、11 选择左移的数据。

# 对跳转指令的处理

> EXE Stage 需要对`jalr`和`b-type(beq, bne, blt, bltu, bge, bgeu)`做分支预测的判断，如果判断分支预测错误，EXE 需要向 IF 发送正确的 re direction_pc, taken 信号，以及冲刷流水线

|        | 跳转预测 | 跳转确认         | 跳转 PC 计算       | pc=pc+4     |
| ------ | -------- | ---------------- | ------------------ | ----------- |
| JAL    | SBP      | 不需要确认       | SBP                | IF->ID->EXE |
| JALR   | SBP      | 不需要确认       | PC=alu_result & ~1 | IF->ID->EXE |
| Branch | SBP      | ALU 确认跳转方向 | SBP                | IF->ID->EXE |

- JAL 指令: SBP 可以 100%预测其跳转的方向和 PC，ALU 不需要做额外的计算
- JALR 指令: 当 SBP 判断`jarl`指令不跳转时，SBP 100%是判断错误了，因此需要 ALU 计算 redirection_pc 和 taken
- B-type 指令: SBP 不可以 100%预测跳转方向，但是可以 100%计算出重定向 PC，需要 ALU 判断跳转方向是否正确

### JALR 指令

1. 如果 SBP 可以预测`jalr`指令，则 EXE Stage 需要 flush 掉`jalr`指令后续的 2 条 prefetch 指令
2. 如果 SBP 不可以预测`jalr`指令，则 EXE Stage 需要计算重定向 pc，并且 flush 掉`jalr`指令后 3 条指令

```verilog
        else if(jalr_d_i) begin
            if(~taken_d_i) begin
                flush_if_e_o       <= 1'b1; // flush 3 instruction fetch by pc+4
                flush_id_e_o       <= 1'b1;
                flush_exe_e_o      <= 1'b1;
                redirection_e_o    <= 1'b1;
                redirection_pc_e_o <= alu_calculation & ~1; // new pc for jalr instruction
            end
            else begin
                flush_if_e_o       <= 1'b0; // flush 2 instruction fetch by pc+4
                flush_id_e_o       <= 1'b1;
                flush_exe_e_o      <= 1'b1;
                redirection_e_o    <= 1'b0;
            end
        end

```

### B-type 指令

由于 IF Stage 中，prefetch 提前 2 个 cycle 给出了取指 pc，所以当 ID 译码判别出一条 b-type 指令之后，该指令后续两条指令都 100%会被取出且送到 ID Stage；ID stage 的重定向 PC 需要 2 个 cycle 才可以取出对应的指令送到 ID 进行译码.

1. sbp 预测 taken==0，alu 判断 taken==0
   - sbp 预测 taken==0 的时候，ID 不会给 IF 发送重定向 rediction_pc, beq 后续第三条指令会被取入
   - alu 判断 taken==0，alu 什么也不用做
2. sbp 预测 taken==0，alu 判断 taken==1
   - sbp 预测 taken==0 的时候，ID 不会给 IF 发送重定向 rediction_pc, beq 后续第三条指令会被取入
   - alu 判断 taken==1，需要冲刷掉 prefetch 的 2 条指令和顺序取指的 1 条指令，**具体表现为设置 IF/ID, ID/EXE, EXE/MEM pipeline register flush=1**
   - <u>并且 alu 需要向 IF 发送 rediction_pc 为跳转目标</u>
3. sbp 预测 taken==1，alu 判断 taken==0
   - sbp 预测 taken==1 的时候，ID 会给 IF 发送重定向 rediction_pc，IF 在 2 个 cycle 之后会将 rediction_pc 对应的指令送到 ID
   - alu 判断 taken==0，需要冲刷掉 rediction_pc 对应的这条指令，**具体表现为设置 ID/IF pipeline register flush=1**
   - <u>并且 alu 需要向 IF 发送 rediction_pc 为顺序取指 pc</u>
4. sbp 预测 taken==1，alu 判断 taken==1
   - sbp 预测 taken==1 的时候，ID 会给 IF 发送重定向 rediction_pc，IF 在 2 个 cycle 之后会将 rediction_pc 对应的指令送到 ID
   - alu 判断 taken==1，说明 ID 重定向是对的，此时需要冲刷掉 b-type 指令后面 prefetch 的 2 条指令, **具体表现为设置 ID/EXE, EXE/MEM pipeline register flush=1**

```verilog
// pipelineEXE.v
        else if(is_branch==1'b1) begin
            case({taken_d_i, alu_taken})
                2'b00: begin
                    // sbp taken, alu taken => don't need to flush instruction
                    flush_if_e_o       <= 1'b0;
                    flush_id_e_o       <= 1'b0;
                    flush_exe_e_o      <= 1'b0;
                    redirection_e_o    <= 1'b0;
                end
                2'b01: begin
                    // sbp not taken, alu taken => flush 3 instructions which are all pc+4
                    flush_if_e_o       <= 1'b1;
                    flush_id_e_o       <= 1'b1;
                    flush_exe_e_o      <= 1'b1;
                    redirection_e_o    <= 1'b1;
                    redirection_pc_e_o <= prediction_pc_d_i; // fetch instruction from sbp
                end
                2'b10: begin
                    // sbp taken, alu not taken => flush 1 rediction instruction
                    flush_if_e_o       <= 1'b1;
                    flush_id_e_o       <= 1'b0;
                    flush_exe_e_o      <= 1'b0;
                    redirection_e_o    <= 1'b1;
                    redirection_pc_e_o <= pc_plus4_d_i + 32'h8; // TODO: change 8 to pc_sequential, to support rvc
                end
                default: begin
                    // sbp taken, alu taken => flush 2 instructions which are all pc+4
                    flush_if_e_o       <= 1'b0;
                    flush_id_e_o       <= 1'b1;
                    flush_exe_e_o      <= 1'b1;
                    redirection_e_o    <= 1'b0;
                end
            endcase
        end

```

# 仿真结果

## jalr 存在数据依赖

```assembly
	.text			# Define beginning of text section
	.global	_start		# Define entry _start

_start:
    # test JALR
    addi x5, x6, 4
    addi x1, x1, 1
    nop
    nop
    nop
    jr x2
    addi x2, x2, 2
    addi x3, x3, 3
    addi x4, x4, 4

stop:
	j stop			# Infinite loop to stop execution

	.end			# End of file

```

期待运行过程：

1. counter ==1: 复位

2. counter ==2: pc=0x000000000

3. counter ==3: 从 I-Memory 取出第一条指令：`addi x5, x6, 4`

4. counter ==4: 指令`addi x5, x6 ,4`进入到 ID 开始译码

5. counter ==5: 指令`addi x1, x1, 1`进入到 ID 开始译码

6. counter ==6: 指令`nop`进入到 ID 开始译码

7. counter ==7: 指令`nop`进入到 ID 开始译码

8. counter ==8: 指令`nop`进入到 ID 开始译码

9. counter ==9: 指令`jr x2`进入到 ID 开始译码, SBP 判断跳转存在数据依赖, 不跳转

10. counter ==10:

    - `addi x2, x2, 2`进入 ID 开始译码

    - 此时`jr x2`属于 EXE Stage，ALU 判断 SBP 对`jr`的判断错误
    - ALU 计算 rediction_pc

11. counter ==11:

    - `addi x3, x3, 2`进入 ID 开始译码

    - ALU pipeline register 输出 redirection 信号和 redirection_pc，IF 级取指 pc 变成 0x000000000
    - ALU pipeline register 输出 flush 信号，**冲刷掉`addi x2, x2, 2`,`addi x3, x3, 3`和`addi x4, x4, 4`**指令

12. counter ==12: 按照 0x 000000000 从 I-Memory 取出指令`addi x5, x6, 4`
    从``counter==3`开始循环: `addi->addi->nop->nop->nop->jr`



## jalr 不存在数据依赖

```assembly
	.text			# Define beginning of text section
	.global	_start		# Define entry _start

_start:
    # test JALR
    addi x5, x6, 4
    addi x1, x1, 1
    nop
    nop
    nop
    jr x2
    addi x2, x2, 2
    addi x3, x3, 3
    addi x4, x4, 4

stop:
	j stop			# Infinite loop to stop execution

	.end			# End of file
```

期待运行过程：

1. counter ==1: 复位
2. counter ==2: pc=0x000000000
3. counter ==3: 从 I-Memory 取出第一条指令：`addi x5, x6, 4`
4. counter ==4: 指令`addi x5, x6 ,4`进入到 ID 开始译码
5. counter ==5: 指令`addi x1, x1, 1`进入到 ID 开始译码
6. counter ==6: 指令`nop`进入到 ID 开始译码
7. counter ==7: 指令`nop`进入到 ID 开始译码
8. counter ==8: 指令`nop`进入到 ID 开始译码
9. counter ==9: 指令`jr x0`进入到 ID 开始译码, SBP 判断跳转不存在数据依赖, 预测跳转
10. counter ==10:
    - `addi x2, x2, 2`指令进入 ID 开始译码
    - ID pipeline register 输出 prediction_pc, IF 取指 pc=0x00000000
    - `jr x0`进入 EXE Stage，ALU 判断 SBP 预测正确，不产生重定向 pc，产生 flush 信号
11. counter ==11:
    - `addi x3, x3, 3`指令进入 ID 开始译码
    - EXE pipeline register 输出 flush 信号，刷新掉`addi x2, x2, 2`和`addi x3, x3, 3`指令
    - 从 I-Memory 取出指令`addi x5, x6, 4`
      从`counter==3`开始循环：`addi, addi, nop, nop, nop, jr`



## B-Type 指令仿真

### sbp not taken, alu not taken

```assembly
	.text			# Define beginning of text section
	.global	_start		# Define entry _start

_start:
    # sbp not taken, alu taken
    addi x5, x6, 4
    addi x1, x1, 1
    nop
    nop
    nop
    beq  x0, x5, stop
    addi x2, x2, 1
    addi x3, x3, 1
    addi x4, x4, 1

stop:
	j stop			# Infinite loop to stop execution

	.end			# End of file
```

期待运行过程：`addi, addi, nop, nop, nop, beq, addi, addi, addi, j`



### sbp not taken, alu taken

```assembly
	.text			# Define beginning of text section
	.global	_start		# Define entry _start

_start:
    # sbp not taken, alu taken
    addi x5, x6, 4
    addi x1, x1, 1
    nop
    nop
    nop
    bne  x0, x5, stop
    addi x2, x2, 1
    addi x3, x3, 1
    addi x4, x4, 1

stop:
	j stop			# Infinite loop to stop execution

	.end			# End of file
```

期待运行过程：`addi, addi, nop, nop, nop, bne, j`



### sbp taken, alu not taken

```assembly
	.text			# Define beginning of text section
	.global	_start		# Define entry _start

_start:
    # sbp taken, alu not taken
    addi x5, x6, 4
    addi x1, x1, 1
    nop
    nop
    nop
    bge  x0, x5, _start
    addi x2, x2, 1
    addi x3, x3, 1
    addi x4, x4, 1

stop:
	j stop			# Infinite loop to stop execution

	.end			# End of file

```

期待运行过程：`addi, addi, nop, nop, nop, bge, addi, addi, addi, j`



### sbp taken, alu taken

```assembly
	.text			# Define beginning of text section
	.global	_start		# Define entry _start

_start:
    # sbp taken, alu taken
    addi x5, x6, 4
    addi x1, x1, 1
    nop
    nop
    nop
    bltu  x0, x5, _start
    addi x2, x2, 1
    addi x3, x3, 1
    addi x4, x4, 1

stop:
	j stop			# Infinite loop to stop execution

	.end			# End of file
```

期待运行过程：`addi, addi, nop, nop, nop, bltu, addi, addi`



## 混合指令

```assembly
	.text			# Define beginning of text section
	.global	_start		# Define entry _start

_start:
    addi x5, x6, 4
    addi x1, x1, 1
    nop
    nop
    nop
    beq  x0, x5, stop
    bne  x0, x5, _start
    j stop
    addi x2, x2, 1
    addi x3, x3, 1
    addi x4, x4, 1
stop:
	j stop			# Infinite loop to stop execution

	.end			# End of file
```

期待运行过程：`addi, addi, nop, nop, nop, beq, bne, j, j, j`



# 流水线冲刷总结

### 冲刷 IF/ID pipeline register 的情况

1. `jal`指令由 id stage 冲刷 IF/ID
2. `jalr`指令 sbp 判断 not taken，由 exe stage 产生 redirection_pc，冲刷 IF/ID
3. `b-type`指令，sbp not taken, alu taken
4. `b-type`指令，sbp taken, alu not taken

### 冲刷 ID/EXE pipeline register 的情况

1. `jal`指令由 id stage 冲刷 ID/EXE
2. `jalr`指令由 exe stage 冲刷 ID/EXE
3. `b-type`指令，sbp not taken, alu taken
4. `b-type`指令，sbp taken, alu taken

### 冲刷 EXE/MEM pipeline register 的情况

1. `jalr`指令由 exe stage 冲刷 ID/EXE
2. `b-type`指令，sbp not taken, alu taken
3. `b-type`指令，sbp taken, alu taken
