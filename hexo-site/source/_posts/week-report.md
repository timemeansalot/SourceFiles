---
title: 付杰周报-20230708
date: 2023-03-08 14:45:34
tags: RISC-V
---

[TOC]

<!--more-->

# 放弃使用香山官方提供的最新的Difftest版本

放弃使用最新版本Difftest的原因如下：

1. 香山最新版本的Github仓库里Difftest只有Scala的版本，无法直接在Verilog中引用
2. 目前最新版本的Difftest**过于复杂**：它支持多核、Cache、Uart、Trap等模块，导致移植MCU_Core到最新版本的Difftest时，需要保证这些模块都真确连线，十分复杂。
   一开始尝试接入最新版本的Difftest，结果调试了一两天还是报错无法看到*有进展的结果*，因此预测将MCU_Core接入到最新版本的Difftest框架中将消耗很久的时间
3. 目前由于没有CSR模块，其实我们的MCU_Core的状态仅有**“PC+Register”**表征，因此Difftest框架只需要在指令提交之后比较PC跟Register即可。
   <u>Difftest核心思想：MCU_Core执行一条指令->Reference Model执行一条指令->比较二者的状态(PC + Register)</u>

> 因此选择了“老版本的Difftest”版本，其实现的效果是：将单周期RISC-V处理器接入到Difftest框架中，比较其每次提交指令后，Register是否跟Reference Model相同，比较符合我们目前的测试需求，接入的难度相当于接入最新版本的Difftest也更加可控。

# 接入Difftest框架做的修改

![image-20230707211721928](https://s2.loli.net/2023/07/12/FPkCghplBJEYzTA.png)

为了将MCU_Core接入到Difftest框架，主要做了如下修改：

1. 修改Verilog代码接入Difftest框架之后的Warning，主要包括代码中的“隐式变量声明、信号位宽不匹配、模块重定义”等Warning。因为Verilator相较于Iverilog对于语法检查更加严格一些。

2. 在top.v中增加接口，因为：

   - Difftest框架需要知道MCU_Core的一些内部信号，如pc, instruction
   - 将一些重要的信号从top引出来，可以在Difftest的时候进行打印，方便判断

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

   如上所示，我们在top的接口中定义了一些信号，我们在Difftest框架中就可以打印相应的信号值

3. 确定MCU_Core提交到difftest 的时机

   - 由于Reference Model是单周期的处理器，其每个Cycle就会提交一条指令；我们的MCU_Core是5级流水线处理器，第一条指令必须等到5个Cycle之后其结果才会写入到Register
   - 我们的MCU由于分支预测器的存在，可能会取一条指令，但是这条指令会被冲刷，因此其不会写入到Register

   可见**MCU_Core中的指令，并不是每一个Cycle都会写入到Register，但是Reference Model一旦执行一条指令，则会在一个Cycle写入到Register**，因此：

   - MCU_Core必须告诉Difftest框架，其在某时刻写入到了Register
   - Difftest框架在收到该信号之后，令Reference Model执行一步，并且将其结果写入到Register

   经过分析发现，我们的MCU_Core不论指令流是何种情况，其在写入Register的时候，都会有wb_en信号为高，因此**我们在top中加入该信号，并且在Difftest中根据该信号来控制Reference Model执行和Difftest比较**。

   ```c
   // difftest/csrc/cpu_exec.c
   /* difftest begin */
   cpu.pc = top->pc; // pc存入cpu结构体
   dump_gpr(); // 寄存器值存入cpu结构体
   if(top->wb_en){ // <- 判断指令提交再进入Difftest
       difftest_step(top->pc);
   }
   /* difftest end */
   ```

4. 增加MCU的I-Memory的读取逻辑，从Difftest框架里读取指令、加载到MCU中

   - 不同于用verilog写的testbench，Difftest框架里初始化都是通过c函数来将编译好的二进制文件读入内存的。
     - 在Difftest代码里，定义了一块内存`pmem`用于存储MCU_Core的指令
     
     - 通过load_img函数来初始化pmem，实现I-Memory的初始化；在verilog写的testbench中，我们是通过readmemh函数来读入二进制文件到内存的
     
     - 在verilog文件中，**指令的读取是通过DPI-C函数，读取`pmem`对应地址的值**；在verilog写的testbench中，指令的读取是直接通过`assign instr = i-memory[addr];`来实现的
     
     - 在top文件中添加I-memory的`sram_output`、`mem_addr`端口，在进行Difftest的时候，通过这两个端口读取指令数据（而不是通过imemory模块读取指令数据）
     
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
     
     - 在c文件中，通过上述top文件的端口，实现从`pmem`读取指令、加载到IF Stage
     
       ![image-20230712153213765](https://s2.loli.net/2023/07/12/r1K576pbits3qCI.png)
     
       

5. 在Register中增加DPI-C函数将CPU的register传递给Difftest模块

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

6. 修复函数 `dump_gpr` in `csrc/cpu_exec`
   该函数的作用是利用DPI-C函数将MCU的registers的数值读取读取到c结构体里(cpu.gpr)，后续Difftest会比较该结构体的值跟Reference Model是否匹配.

   运行Difftest的时候发现，cpu.gpr[i]的值，实际上对应的是寄存器r[i+1]，导致Difftest报错，因此将cpu_gpr[i]更改为cpu_gpr[i-1]。

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

# MCU_Core接入Difftest结果

![image-20230707210706875](https://s2.loli.net/2023/07/07/QD8nlf1BTNMxYGo.png)

目前MCU_Core已经接入到了Difftest框架，Difftest检测到MCU_Core运行的结果跟Reference Model的结果不同，会报错，并且给出报错的信息，如上图所示。

1. 后续会陆续根据Difftest的提示，陆续修改MCU_Core中的bug，直到通过所有的测试，达到如下图所示效果，出现`HIT GOOD TRAP`字样：

   ![image-20230707210602556](https://s2.loli.net/2023/07/07/nmXbVy69HxjOtwJ.png)

2. 也会预先研究如何在Difftest中测试一些复杂事件的比较，例如Trap、CSR比较

# 发现和修复的bug

1. 每条指令与其对应的PC差了4

   - [x] bug已修复

   - bug描述：由ID Stage来保证每一条指令跟其对应的pc相匹配，但是当某条指令计算需要用到pc的值时，错误的将next_pc的值给了源操作数，导致结果大了4

     ![image-20230714103303910](https://s2.loli.net/2023/07/14/Pq9FQUvcLDKTZIp.png)

   - bug修复：将当前pc的值赋值给源操作数`rs1_d_o`

     ```verilog
     // pipelineID.v
     else begin
         // rs1_d_o <= pc_next; // alu source from pc+4
         rs1_d_o <= pc_instr; // alu source from pc
     end
     ```

   

1. reset之后第一条指令的pc时序问题
   
   - [x] bug已修复
   
   - bug描述：resetn触发之后，ID会强制跳转到初始PC，但是之前MCU初始PC是0x00000000，因此每次resetn之后pc跳转都会出错
   
   - bug修复：将resetn之后的redirection_d_o修复为0x80000000
     ```verilog
       // file: pipelineID.v
       assign redirection_d_o = ({32{~resetn_delay | flush_i}} & 32'h80000000)|        // <- fix bug
                                ({32{ptnt_e_i & ~branchJAL_o}} & pc_next)| // sbp taken, alu not taken
                                ({32{ptnt_e_i &  branchJAL_o}} & redirection_pc)| // sbp taken, alu not taken, following by JAL
                                ({32{ redirection_e_i}}  & redirection_pc_e_i)| // pc from EXE
                                ({32{~redirection_e_i}}  & redirection_pc);  // pc from SBP
     ```
   
3. MCU内存跟riscv内存存储方式不一致

   - [ ] bug已修复

   - bug描述：MCU跟Difftest的二进制程序，其大小端方向不一致，因此Difftest得到的镜像文件加载之后，需要调换其顺序才可以得到指令

     > PS: riscv采用小端存放的格式，对于32bits的指令一条指令aabbccdd，其存储为ccddaabb

   - bug修复：跟MCU之前测试时二进制程序编译有关、跟Difftest二进制程序编译有关、跟MCU imemory设计有关

     ![image-20230712170217686](https://s2.loli.net/2023/07/12/EHPlZIyu97b6ojk.png)

3. NOP指令导致错误的`wb_en`

   - [x] bug已修复

   - bug描述：需要被冲刷的指令，其行为会被翻译成一条NOP指令，但是NOP指令本质上是`addi x0, x0, 0`，译码单元对于`addi`指令会判断其`wb_en=1`，因此当系统resetn出发时，其面几条NOP指令会导致`wb_en=1`，进而导致Difftest开始比较MCU跟Reference Model，进而导致比较失败

   - bug修复：译码的时候，如果发现指令是NOP指令，则`wb_en=0`，即`assign wb_en_o = instruction_i != 32'h00000013;`

     ![image-20230712171228993](https://s2.loli.net/2023/07/12/vE7Z2KzFRsWgcAL.png)
