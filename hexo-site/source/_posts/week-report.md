# TODO

- [ ] ID:
  - [ ] bypass
  - [x] alu_op 18 bits
  - [x] regfile
  - [x] sbp for jalr: sbp can calculate taken, but may fail to calculate pc
- [x] EXE
  - [x] EXE: jalr, newPC=(rd+offset)&~1
  - [x] 集成 ALU
  - [x] 测试 ALU 加入之后重定向成功
  - [x] 加入 Flush 信号、resetn
  
    
- [x] instru
  - [x] jal
  - [x] jalr
  - [x] beq
  - [x] bne
  - [x] blt
  - [x] bge
  - [x] bltu
  - [x] bgeu
- [x] Flush：IF、ID、EXE 的 flush 信号会根据 Hazard Unit 的 flush 信号激活
- [ ] Stall：IF、ID 的 enable 信号会根据 Hazard Unit 的 stall 信号激活

## IF Stage

1. PC -> I-Memory -> Instruction: 一共有 2 个 cycle 的 delay，需要保证 PC 和 instruction 在流水线上是匹配的，在代码里使用了一个额外的`pc_delay`寄存器来提供额外一个 cycle 的 PC 延迟
   ![if_id_sbp](/Users/fujie/Pictures/typora/IF/if_id_sbp.svg)

2. 当流水线刷新之后，新地址对应的指令在 2 个 cycle 之后送到 ID Stage ，因此其后续两个 cycle 的指令都是无效指令，看作 2 条 nop 指令

3. EXE 如果和 ID 同时发来了重定向信号，则 EXE 的信号优先级更高：因为EXE的指令更老

   ```verilog
   // pipelineIF.v
   assign pc_mux = (taken_e_i == 1'b1) ? redirection_e_i:
     							(taken_d_i == 1'b1) ? redirection_d_i : pc_register;
   ```

   ![flushID](/Users/fujie/Pictures/typora/IF/flushID.svg)

## ID Stage

1. RF(register File)异步读出、同步写入

2. 静态分支预测 SBP(static branch prediction)
   - `JAL`: SBP 预测`taken=1`，且`pc=pc+offset`，ID 需要输出 flush 信号来清楚 prefetch 的 2 条指令，**具体表现为设置 IF/ID, ID/EXE pipeline register flush=1**
   - `b-type`: 采取 BTFN(backward taken, forward not taken), 且`pc=pc+offset`
   - `JALR`: 分情况讨论
     - 如果 rs1 是 x0,或者 rs1 没有数据依赖：SBP 预测`taken=1`，且`pc=(rd+offset)&~1`
     - 如果 rs1 有数据依赖：SBP 预测`taken=0`
       ![](/Users/fujie/Pictures/typora/pipeline/jalr.svg)
3. bypass: ID 级根据 Hazard 的信号，在需要 bypass 的时候，选择合适的 bypass 信号取代 RF 里读出去的运算数

## EXE Stage

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
   - <u>并且 alu 需要向 IF 发送 rediction_pc为跳转目标</u>
3. sbp 预测 taken==1，alu 判断 taken==0
   - sbp 预测 taken==1 的时候，ID 会给 IF 发送重定向 rediction_pc，IF 在 2 个 cycle 之后会将 rediction_pc 对应的指令送到 ID
   - alu 判断 taken==0，需要冲刷掉 rediction_pc 对应的这条指令，**具体表现为设置 ID/IF pipeline register flush=1**
   - <u>并且 alu 需要向 IF 发送 rediction_pc为顺序取指pc</u>
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

## MEM Stage

1. MEM 和 EXE 需要 resetn 信号，否则系统 reset 之后，MEM Stage 输出的`reg_wb_en`会是 x，传输给 ID Stage 之后，会导致第一次读取 RF 时读出的也是 x

## WB Stage

1. 由于 ID 级的 RF 需要一个 cycle 才可以写入，因此 WB Stage 的 output 被定义为 wire 类型，从而避免额外一个 cycle 的 RF 写入延迟，此时 WB 变成纯组合逻辑

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

![image-20230512151143360](/Users/fujie/Pictures/typora/image-20230512151143360.png)

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

![image-20230512152204442](/Users/fujie/Pictures/typora/image-20230512152204442.png)

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

![image-20230512155556061](/Users/fujie/Pictures/typora/image-20230512155556061.png)

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

![image-20230512155913379](/Users/fujie/Pictures/typora/image-20230512155913379.png)

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

![image-20230512160412862](/Users/fujie/Pictures/typora/image-20230512160412862.png)

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

### ![image-20230512160631459](/Users/fujie/Pictures/typora/image-20230512160631459.png)

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

![image-20230512163723257](/Users/fujie/Pictures/typora/image-20230512163723257.png)

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
