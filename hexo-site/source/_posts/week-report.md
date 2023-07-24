---
title: 付杰周报-20230708
date: 2023-03-08 14:45:34
tags: RISC-V
---

[TOC]

## 更改指令 commit 的时机

![](https://s2.loli.net/2023/07/21/e8URhdaPM4lTC6z.png)
**我们不能简单的以`wb_en`来判断一条指令是否提交**，因为 branch 指令其 wb_en 是 0，但是正常情况下 branch 指令是需要提交的，因此需要通过 hazard 以及 reset 来判断指令提交，具体如下：

1.  判断第一条指令的提交： `resetn`触发之后，2 个 cycle 才可以读出第一条指令，第一条指令经过 5 个 cycle 才能提交
2. 后续指令需要根据 hazard unit 的`flush`信号来判断是否会被冲刷，hazard unit 只对 ID 进行冲刷
3. 流水线 stall 的时候，需要暂停提交



主要在 top.v 里增加了如下内容

```verilog
    `ifdef DIFFTEST
    // instruction commit
    reg resetn_d, resetn_d_d;
    reg commit_en_exe, commit_en_mem, commit_en_wb, commit_en_delay;
    wire commit_en_id;
    assign id_instr=instruction_f_o;
    // TODO: add stall logic consideration for instruction commit

    always @(posedge clk ) begin
        resetn_d <= resetn;
        resetn_d_d <= resetn_d;
    end

    assign commit_en_id = ~flush_d_i & resetn_d_d;
    assign commit_en    = commit_en_delay;
    always @(posedge clk ) begin
        if(~resetn) begin
            commit_en_exe <= 0;
            commit_en_mem <= 0;
            commit_en_wb  <= 0;
            commit_en_delay <= 0;
        end
        else begin
            commit_en_exe   <= commit_en_id;
            commit_en_mem   <= commit_en_exe;
            commit_en_wb    <= commit_en_mem;
            commit_en_delay <= commit_en_wb;
        end
    end
    `endif
```

### 增加ecall指令
在decoder.v里通过DPI-C函数增加ecall指令，这样在译码到ecall指令的时候，会通知DIFFTEST，riscv-test也是一ecall来表明测试结束的

```verilog
    `ifdef DIFFTEST
    wire inst_ecall;    
    assign inst_ecall = instruction_i == 32'h00000073;

    always @(*) begin
      if (inst_ebreak) ecall();
    end
    `endif
```
## 新发现的 bug

1. RV32 R-Type 指令跟 RV32 M 指令译码错误
   - [x] bug 已修复
   - bug 描述：R-Type 指令`instruction[25]==0`，M 指令`instruction[25]==1`，在`decoder.v`文件里，把该条件写反了
   - bug 修复：如果`instruction[25]==0`则按照 R-Type 指令进行译码
2. EXE Stage 在`redirection_e_o`信号对`JAL`指令判断错误

   - [x] bug 已修复
   - bug 描述：EXE Stage 需要判断 SBP 对于 Branch 的分支预测是否正确；但是 EXE Stage 不需要判断 SBP 对于`JAL`指令判断是否正确
   - bug 修复：EXE Stage 在判断的时候，首先判断是否是 Branch 指令，再判断 SBP 预测是否正确；从而避免多此一举的对`JAL`是否预测正确判断

     ```bash
        diff --git a/npc/vsrc/pipelineEXE.v b/npc/vsrc/pipelineEXE.v
        index 8f44516..407184c 100644
        --- a/npc/vsrc/pipelineEXE.v
        +++ b/npc/vsrc/pipelineEXE.v
        @@ -21,6 +21,7 @@ module pipelineEXE (
        +    input wire        btype_d_i,       // instruction is branch type instruction
  
        @@ -128,7 +129,7 @@ module pipelineEXE (
             end
             assign redirection_e_o = st_e_i? redirection_r :
        -                                    (taken_d_i^alu_taken)|(jalr_d_i&~taken_d_i);
        +                                    ( btype_d_i & taken_d_i^alu_taken)|(jalr_d_i&~taken_d_i);
     ```

3. lui 指令需要 bypass 的时候，bypass 了错误的值

   - [x] bug 已修复
   - bug 描述：当一条指令的源寄存器跟它上一条指令的目的寄存器想同时，则会存在 EXE->ID 的 bypass，将 alu_result bypass 到 ID Stage.
     目前 EXE Stage 的代码只会 bypass alu_result，但是对于`LUI`指令，其写回到寄存器的指不是 alu 的计算结果，而是`extended_imm`
     ![](https://s2.loli.net/2023/07/21/ZKWGEwJUb9A8poO.png)
   - bug 修复：在 bypass 的时候，需要根据写回到寄存器的来源，选择正确的源进行 bypass，一共有 4 种写会到寄存器的源：
     1. alu_result
     2. extended_imm
     3. next_pc
     4. load_data <- only in MEM stage bypass

   ```bash
        diff --git a/npc/vsrc/pipelineEXE.v b/npc/vsrc/pipelineEXE.v
        index b81fbbe..62bb8e2 100644
        --- a/npc/vsrc/pipelineEXE.v
        +++ b/npc/vsrc/pipelineEXE.v
        -    assign bypass_e_o=alu_calculation;
        +    assign bypass_e_o = {32{result_src_d_i[0]}} & alu_calculation |
        +                        {32{result_src_d_i[1]}} & extended_imm_d_i|
        +                        {32{result_src_d_i[3]}} & pc_plus4_d_i;
   ```

## 测试通过的 riscv-tests

1. andi
   ![](https://s2.loli.net/2023/07/21/VCwrtB6vZhkdTNR.png)
2. ori
   ![ori](https://s2.loli.net/2023/07/21/QPRkNrMflacEoAj.png)
3. xori
   ![xori](https://s2.loli.net/2023/07/21/R5YbuGZrDVf6cgj.png)
4. lui
   ![lui](https://s2.loli.net/2023/07/21/W8MKySYt6eAOnI1.png)

TODO: must use 32 bits instead of 64 bits
![must 32](https://s2.loli.net/2023/07/21/myp1vc9XGajgwSP.png)
