---
title: 付杰周报-20230708
date: 2023-03-08 14:45:34
tags: RISC-V
---

[TOC]

<!--more-->

# 放弃使用香山官方提供的最新的 Difftest 版本

放弃使用最新版本 Difftest 的原因如下：

1. 香山最新版本的 Github 仓库里 Difftest 只有 Scala 的版本，无法直接在 Verilog 中引用
2. 目前最新版本的 Difftest**过于复杂**：它支持多核、Cache、Uart、Trap 等模块，导致移植 MCU_Core 到最新版本的 Difftest 时，需要保证这些模块都真确连线，十分复杂。
   一开始尝试接入最新版本的 Difftest，结果调试了一两天还是报错无法看到*有进展的结果*，因此预测将 MCU_Core 接入到最新版本的 Difftest 框架中将消耗很久的时间
3. 目前由于没有 CSR 模块，其实我们的 MCU_Core 的状态仅有**“PC+Register”**表征，因此 Difftest 框架只需要在指令提交之后比较 PC 跟 Register 即可。
   <u>Difftest 核心思想：MCU_Core 执行一条指令->Reference Model 执行一条指令->比较二者的状态(PC + Register)</u>

> 因此选择了“老版本的 Difftest”版本，其实现的效果是：将单周期 RISC-V 处理器接入到 Difftest 框架中，比较其每次提交指令后，Register 是否跟 Reference Model 相同，比较符合我们目前的测试需求，接入的难度相当于接入最新版本的 Difftest 也更加可控。

# 接入 Difftest 框架做的修改

![image-20230707211721928](https://s2.loli.net/2023/07/12/FPkCghplBJEYzTA.png)

为了将 MCU_Core 接入到 Difftest 框架，主要做了如下修改：

1. 修改 Verilog 代码接入 Difftest 框架之后的 Warning，主要包括代码中的“隐式变量声明、信号位宽不匹配、模块重定义”等 Warning。因为 Verilator 相较于 Iverilog 对于语法检查更加严格一些。

2. 在 top.v 中增加接口，因为：

   - Difftest 框架需要知道 MCU_Core 的一些内部信号，如 pc, instruction
   - 将一些重要的信号从 top 引出来，可以在 Difftest 的时候进行打印，方便判断

   ```verilog
   // mcu_core/top.v
   module top(
       input  wire        clk,
       input  wire        resetn,
       // signals used by difftest
       output wire [31:0] pc,
       output wire [63:0] instr,
       output wire        wb_en,
       output wire [ 4:0] wb_idx,
       output wire [31:0] wb_data,
       output wire [31:0] id_instr,
       output wire [20:0] op_code,
       output wire [31:0] src1,
       output wire [31:0] src2,
       output wire [ 3:0] wb_src,
       output wire [31:0] alu_result
       // signals used by difftest
   );
   ```

   ```c
   // difftest/csrc/cpu_exec.c
   static void execute(uint64_t n) {
     for (;n > 0; n --) {
       g_nr_guest_inst ++;

       printf("Top: instr = 0x%x\n", top->instr);
       printf("ID Stage: id_instr=0x%x, opcode = %d, src1 = 0x%x, src2 = 0x%x, wb_src= %d\n", top->id_instr, top->op_code, top->src1, top->src2, top->wb_src);
       printf("EXE stage: alu_result = 0x%x\n", top->alu_result);
       printf("WB Stage: wb_en=%d, idx=%d, data=%x\n", top->wb_en,
              top->wb_idx, top->wb_data);

   ```

   ```bash
    Difftest仿真输出
   Top: instr = 0x413
   ID Stage: id_instr=0x413, opcode = 1, src1 = 0x0, src2 = 0x0, wb_src= 1
   EXE stage: alu_result = 0x0
   WB Stage: wb_en=0, idx=0, data=0
   npc read instr
   Read I-Memory: addr = 0x80000004, ins= 0x00009117
   NO.2-> pc: 0x80000004, instr: 0x9117, asm: auipc        sp, 9
   NO.2-> pc: 0x80000004, instr: 0x9117, asm: auipc        sp, 9
   C-> pmem_read 80000000: 0x0
   Read I-Memory: addr = 0x80000000, ins= 0x00000413
   pmem_read_rtl: raddr = 0x80000000, rdata= 413
   ```

   如上所示，我们在 top 的接口中定义了一些信号，我们在 Difftest 框架中就可以打印相应的信号值

3. 确定 MCU_Core 提交到 difftest 的时机

   **我们不能简单的以`wb_en`来判断一条指令是否提交**，因为 branch 指令其 wb_en 是 0，但是正常情况下 branch 指令是需要提交的，因此需要通过 hazard 以及 reset 来判断指令提交，具体如下：

   1. 判断第一条指令的提交： `resetn`触发之后，2 个 cycle 才可以读出第一条指令，第一条指令经过 5 个 cycle 才能提交
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

~~- 由于 Reference Model 是单周期的处理器，其每个 Cycle 就会提交一条指令；我们的 MCU_Core 是 5 级流水线处理器，第一条指令必须等到 5 个 Cycle 之后其结果才会写入到 Register~~
~~- 我们的 MCU 由于分支预测器的存在，可能会取一条指令，但是这条指令会被冲刷，因此其不会写入到 Register~~

~~可见**MCU_Core 中的指令，并不是每一个 Cycle 都会写入到 Register，但是 Reference Model 一旦执行一条指令，则会在一个 Cycle 写入到 Register**，因此：~~

~~- MCU_Core 必须告诉 Difftest 框架，其在某时刻写入到了 Register~~
~~- Difftest 框架在收到该信号之后，令 Reference Model 执行一步，并且将其结果写入到 Register~~

~~经过分析发现，我们的 MCU_Core 不论指令流是何种情况，其在写入 Register 的时候，都会有 wb_en 信号为高，因此**我们在 top 中加入该信号，并且在 Difftest 中根据该信号来控制 Reference Model 执行和 Difftest 比较**。~~

~~```c~~
~~// difftest/csrc/cpu_exec.c~~
~~/_ difftest begin _/~~
~~cpu.pc = top->pc; // pc 存入 cpu 结构体~~
~~dump_gpr(); // 寄存器值存入 cpu 结构体~~
~~if(top->wb_en){ // <- 判断指令提交再进入 Difftest~~
~~ difftest*step(top->pc);~~
~~}~~
~~/* difftest end \_/~~
~~```~~

4. 增加 MCU 的 I-Memory 的读取逻辑，从 Difftest 框架里读取指令、加载到 MCU 中

   - 不同于用 verilog 写的 testbench，Difftest 框架里初始化都是通过 c 函数来将编译好的二进制文件读入内存的。

     - 在 Difftest 代码里，定义了一块内存`pmem`用于存储 MCU_Core 的指令
     - 通过 load_img 函数来初始化 pmem，实现 I-Memory 的初始化；在 verilog 写的 testbench 中，我们是通过 readmemh 函数来读入二进制文件到内存的
     - 在 verilog 文件中，**指令的读取是通过 DPI-C 函数，读取`pmem`对应地址的值**；在 verilog 写的 testbench 中，指令的读取是直接通过`assign instr = i-memory[addr];`来实现的
     - 在 top 文件中添加 I-memory 的`sram_output`、`mem_addr`端口，在进行 Difftest 的时候，通过这两个端口读取指令数据（而不是通过 imemory 模块读取指令数据）

       ```verilog
       module pipelineIF
       (
           input wire        clk,
           input wire        resetn,
       	// ....

           // DIFFTEST
           `ifdef DIFFTEST
           input wire [31:0] imemory_output,
           output wire [31:0] imem_addr,
           `endif
           /* output signals to ID stage */
           output wire [31:0] instruction_f_o

       );
           `ifdef DIFFTEST
           reg [31:0] sram_output_reg;
           always @(posedge clk ) begin
               // delay one cycle because I-Memory has 1 cycle read delay but c function don't has delay
               sram_output_reg <= imemory_output;
           end
           // read I-Memory through DPI-C, TOOD: fix this reorder
           assign sram_output = {sram_output_reg[15:0], sram_output_reg[31:16]};
           assign imem_addr   = mem_addr;
           assign if_ir = instruction_f_o;
           `else


           // I-Memory instance
           imemory u_imemory(
               //ports
               .clk    		( clk    		),
               .resetn 		( resetn 		),
               .ceb    		( ~ceb    		),
               .web    		( web    		),
               .A      		( sram_addr  	),
               .Q      		( sram_output  	) // read instruction from imemory in MCU
           );
           `endif
           // ...

       endmodule
       ```

     - 在 c 文件中，通过上述 top 文件的端口，实现从`pmem`读取指令、加载到 IF Stage

       ![image-20230712153213765](https://s2.loli.net/2023/07/12/r1K576pbits3qCI.png)

5. 在 Register 中增加 DPI-C 函数将 CPU 的 register 传递给 Difftest 模块

   ```verilog
   import "DPI-C" function void set_gpr_ptr(input logic [63:0] a []); // add DPI-C function
   module regfile
       (
       input  wire                              clk_i,
       input  wire                              resetn_i,

       output wire    [REG_DATA_WIDTH-1 :0]     rs1_data_o, // rd1
       //....
       );
   	//.....
       // regfile其余部分均保持不变即可
       //.....

       initial set_gpr_ptr(regfile_data); // <- 使用该DPI-C函数将mcu_core的register状态传递给Difftest模块

   endmodule
   ```

   ![image-20230707210809687](https://s2.loli.net/2023/07/07/hjYRv8Ps32GOZTV.png)

6. 适配 32 bit MCU
   MCU 是 32 bit 的，其 gpr 宽度为 32，但是 Difftest 框架默认是 64bits，如果不修改 difftest 中读取 MCU gpr 的 C 函数，则会读到错误的数据

   ```bash
        --- a/npc/csrc/npc_cpu/npc_exec.c
        +++ b/npc/csrc/npc_cpu/npc_exec.c
        @@ -24,13 +24,13 @@ const char *regs[] = {
         };

         // 一个输出RTL中通用寄存器的值的示例
        -uint64_t *cpu_gpr = NULL;
        +uint32_t *cpu_gpr = NULL;
         void set_gpr_ptr(const svOpenArrayHandle r) {
        -  cpu_gpr = (uint64_t *)(((VerilatedDpiOpenVar*)r)->datap());
        +  cpu_gpr = (uint32_t *)(((VerilatedDpiOpenVar*)r)->datap());
         }
         void dump_gpr() {
           for (int i = 0; i < 32; i++) {
        -    cpu.gpr[i] = cpu_gpr[i-1]; // i-1 to make index correct in DPI-C
        +    cpu.gpr[i] = cpu_gpr[i]; // i-1 to make index correct in DPI-C
           }
         }
   ```

   ```bash
    --- a/npc/vsrc/regfile.v
    +++ b/npc/vsrc/regfile.v
    @@ -5,7 +5,7 @@ file: register file in ID stage
     author: fujie
     time: 2023年 4月28日 星期五 16时16分32秒 CST
     */
    -import "DPI-C" function void set_gpr_ptr(input logic [63:0] a []); // add DPI-C function
    +import "DPI-C" function void set_gpr_ptr(input logic [31:0] a []); // add DPI-C function
   ```

7. 修复函数 `dump_gpr` in `csrc/cpu_exec`
   该函数的作用是利用 DPI-C 函数将 MCU 的 registers 的数值读取读取到 c 结构体里(cpu.gpr)，后续 Difftest 会比较该结构体的值跟 Reference Model 是否匹配.

   运行 Difftest 的时候发现，cpu.gpr[i]的值，实际上对应的是寄存器 r[i+1]，导致 Difftest 报错，因此将 cpu_gpr[i]更改为 cpu_gpr[i-1]。

   ```c
    uint64_t *cpu_gpr = NULL;
    void set_gpr_ptr(const svOpenArrayHandle r) {
      cpu_gpr = (uint64_t *)(((VerilatedDpiOpenVar*)r)->datap());
    }
    void dump_gpr() {
      for (int i = 0; i < 32; i++) {
        cpu.gpr[i] = cpu_gpr[i-1]; // i-1 to make index correct in DPI-C
      }
    }
   ```

# MCU_Core 接入 Difftest 结果

![image-20230707210706875](https://s2.loli.net/2023/07/07/QD8nlf1BTNMxYGo.png)

目前 MCU_Core 已经接入到了 Difftest 框架，Difftest 检测到 MCU_Core 运行的结果跟 Reference Model 的结果不同，会报错，并且给出报错的信息，如上图所示。

1. 后续会陆续根据 Difftest 的提示，陆续修改 MCU_Core 中的 bug，直到通过所有的测试，达到如下图所示效果，出现`HIT GOOD TRAP`字样：

   ![image-20230707210602556](https://s2.loli.net/2023/07/07/nmXbVy69HxjOtwJ.png)

2. 也会预先研究如何在 Difftest 中测试一些复杂事件的比较，例如 Trap、CSR 比较

# 发现和修复的 bug

1. 每条指令与其对应的 PC 差了 4

   - [x] bug 已修复

   - bug 描述：由 ID Stage 来保证每一条指令跟其对应的 pc 相匹配，但是当某条指令计算需要用到 pc 的值时，错误的将 next_pc 的值给了源操作数，导致结果大了 4

     ![image-20230714103303910](https://s2.loli.net/2023/07/14/Pq9FQUvcLDKTZIp.png)

   - bug 修复：将当前 pc 的值赋值给源操作数`rs1_d_o`

     ```verilog
     // pipelineID.v
     else begin
         // rs1_d_o <= pc_next; // alu source from pc+4
         rs1_d_o <= pc_instr; // alu source from pc
     end
     ```

1. reset 之后第一条指令的 pc 时序问题

   - [x] bug 已修复
   - bug 描述：resetn 触发之后，ID 会强制跳转到初始 PC，但是之前 MCU 初始 PC 是 0x00000000，因此每次 resetn 之后 pc 跳转都会出错
   - bug 修复：将 resetn 之后的 redirection_d_o 修复为 0x80000000
     ```verilog
       // file: pipelineID.v
       assign redirection_d_o = ({32{~resetn_delay | flush_i}} & 32'h80000000)|        // <- fix bug
                                ({32{ptnt_e_i & ~branchJAL_o}} & pc_next)| // sbp taken, alu not taken
                                ({32{ptnt_e_i &  branchJAL_o}} & redirection_pc)| // sbp taken, alu not taken, following by JAL
                                ({32{ redirection_e_i}}  & redirection_pc_e_i)| // pc from EXE
                                ({32{~redirection_e_i}}  & redirection_pc);  // pc from SBP
     ```

1. MCU 内存跟 riscv 内存存储方式不一致

   - [ ] bug 已修复

   - bug 描述：MCU 跟 Difftest 的二进制程序，其大小端方向不一致，因此 Difftest 得到的镜像文件加载之后，需要调换其顺序才可以得到指令

     > PS: riscv 采用小端存放的格式，对于 32bits 的指令一条指令 aabbccdd，其存储为 ccddaabb

   - bug 修复：跟 MCU 之前测试时二进制程序编译有关、跟 Difftest 二进制程序编译有关、跟 MCU imemory 设计有关

     ![image-20230712170217686](https://s2.loli.net/2023/07/12/EHPlZIyu97b6ojk.png)

1. NOP 指令导致错误的`wb_en`

   - [x] bug 已修复

   - bug 描述：需要被冲刷的指令，其行为会被翻译成一条 NOP 指令，但是 NOP 指令本质上是`addi x0, x0, 0`，译码单元对于`addi`指令会判断其`wb_en=1`，因此当系统 resetn 出发时，其面几条 NOP 指令会导致`wb_en=1`，进而导致 Difftest 开始比较 MCU 跟 Reference Model，进而导致比较失败

   - bug 修复：译码的时候，如果发现指令是 NOP 指令，则`wb_en=0`，即`assign wb_en_o = instruction_i != 32'h00000013;`

     ![image-20230712171228993](https://s2.loli.net/2023/07/12/vE7Z2KzFRsWgcAL.png)

## 更改指令 commit 的时机

![](https://s2.loli.net/2023/07/21/e8URhdaPM4lTC6z.png)
**我们不能简单的以`wb_en`来判断一条指令是否提交**，因为 branch 指令其 wb_en 是 0，但是正常情况下 branch 指令是需要提交的，因此需要通过 hazard 以及 reset 来判断指令提交，具体如下：

1.  判断第一条指令的提交： `resetn`触发之后，2 个 cycle 才可以读出第一条指令，第一条指令经过 5 个 cycle 才能提交
2. 后续指令需要根据 hazard unit 的`flush`信号来判断是否会被冲刷，hazard unit 只对 ID 进行冲刷
3. 流水线 stall 的时候，需要暂停提交

### 增加ecall指令
在decoder.v里通过DPI-C函数增加ecall指令，这样在译码到ecall指令的时候，会通知DIFFTEST，riscv-test也是一ecall来表明测试结束的


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

TOOD: 添加 difftest commit 的说明

TODO: must use 32 bits instead of 64 bits
![must 32](https://s2.loli.net/2023/07/21/myp1vc9XGajgwSP.png)
