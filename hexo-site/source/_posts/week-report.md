---
title: 付杰周报-20230701
date: 2023-03-08 14:45:34
tags: RISC-V
---

[TOC]

<!--more-->

# 成功接入到 Difftest，编译通过

> DIFFTEST 的比对对象是两个核，一个是用户设计的核，一个是参考核。 比对原理是设计核在每提交一条指令的同时使参考核执行相同的指令，之后比对所有的通用寄存器和 csr 寄存器的值，如果完全相同则认为设计核执行正确

## MCU 接入 Difftest 步骤

1. **<u>编译 NEMU 作为参考对象</u>**，即 Golden Model。NEMU 是一个功能完备的模拟器，支持 x86/mips32/riscv32/riscv64 等 ISA

   - 克隆 NEMU 的 GitHub 仓库到本地
   - 在编译 NEMU 之前需要指定想要模拟的 ISA（因为 NEMU 支持多种 ISA）：`make menuconfig`
     ![](https://s2.loli.net/2023/06/29/JiOsqDT7Gh8opdf.png)
   - 在 NEMU 目录下使用`make`命令进行编译，得到 nemu-interpreter-so 动态链接文件，
     该文件会在 Difftest 编译时被引用

2. 在 <u>**MCU Core 中例化 Difftest 模块**</u>

   1. 为 Difftest 测试创建如下的目录结构
      ```bash
          DifftestFramework
          ├── bin
          ├── nemu
          └── NOOP
              ├── difftest
              └── CPU
                 ├── Core.v
                 ├── Decode.v
                 ├── Execution.v
                 ├── InstFetch.v
                 ├── Instructions.v
                 ├── Ram.v
                 ├── RegFile.v
                 └── SimTop.v
      ```
      - bin: 测试文件
      - nemu: 指令集模拟器，用于作为比较的 golden model
      - difftest: 香山团队提供的 difftest 框架
      - CPU: 存放 MCU_core 实现及 SimTop
        - Core.v: MCU_core 文件，该文件里例化了各个流水线部件、**difftest 里的组件**(将对应的信号传递给 difftest)
        - SimTop.v：difftest 框架默认的顶层文件，在这个文件里需要例化 MCU_core
        -
   2. 在 MCU_core 里例化各级流水线模块以及 Difftest 模块

      > 数据流传递方向可简单地认为是 `MCU_core.v`->`difftest.v`->`interface.h`->`difftest.cpp`

      - difftest.v 中定义了所有 dpic 相关的 verilog module 信息，
        这些 module 中会调用 c 函数用来传输信号。这些 module 会被设计核实例化用来传输信号。
      - mycpu_top.v 中实例化了 difftest.v 中定义的 module。
      - interface.h 是 c 函数的实现，c 函数将设计核的信号赋值给 difftest 中的变量。

      <u>有两种方法可以将以 verilog 编写的 MCU_core 链接入 Difftest 框架</u>：

      1. 参考龙芯团队[chiplab 开源项目中接入 Difftest](https://chiplab.readthedocs.io/zh/latest/Simulation/difftest.html)
         的文档。
         - 龙芯团队采用的是 verilog 来编写其 SoC
         - 处理器支持的指令集其 longarch，因此他们重构了 NEMU 以支持 longarch ISA
         - 他们接入 difftest 时直接有现成的 difftest.v 文件可以例化
         - 其给出的 Difftest Demo 可以在服务器上克隆下来并且跑通
      2. 参考一生一芯团队给出的 Difftest 相关教程、NEMU 相关教程
         - YSYX 团队最先提出在处理器设计中引入 Difftest 框架
         - YXYS 团队给出了 NEMU、以及 Difftest 的[源码解析](https://ysyx.oscc.cc/docs/ics-pa/0.6.html#git-usage)
         - 目前 YSYX 团队文档多以 Chisel 来写 Difftest 以及 SoC，其接入 YSYX 框架的原理是：
           先在 Chisel 语言下将处理器核跟 Difftest 模块链接，再将 Chisel 编译成 Verilog，
           在 Verilog 里直接就实现了 Difftest 模块的例化。
         - 若需要在 YSYX 的基础上进行，我们可以先得到其 Verilog 文件，  
           再接入 MCU_core: `mill playground.runMain CPU.rv64_1stage.u_simtop`

      ![](https://s2.loli.net/2023/06/29/JTnzN795uOwBWvQ.png)

   3. 在 **<u>SimTop.v 里例化 MCU_core</u>**，然后通过 Difftest 的 Makefile 文件编译整个工程，可以得到 emu 可执行文件
      1. Difftest 框架规定必须在 **SimTop** 文件里例化 MCU_core，因为 Difftest 的 Makefile 里写死了
      2. Difftest 的 Makefile 编译会首先将 SimTop.v 编译成`VSimTop.h`, `VSimTop.cpp`等文件，
         供后续编译 C++文件调用
      3. Difftest 编译 emu 文件的时候，会引用 VSimTop 等文件以及 nemu-interpreter-so 文件、也会载入 bin 文件以初始化 I-Memory.

# 运行不通过，程序 abort

![image-20230701082440062](https://s2.loli.net/2023/07/01/5cs8iLybhG2EkKN.png)

过去一周按照 YSYX 的 Difftest 测试框架，首先编译 Chisel 文件得到了 Verilog 文件，然后在 VSimTop.v 文件里，接入了我们的 MCU_core；
然后成功编译出了 emu 可执行文件，但是**在执行该 emu 文件的时候，程序并不能正确运行**

经过分析觉得可能的原因有如下两点：

1. SoC Core 结构不同，我们的 I-Memory 是放在 IF 内部的，
   Difftest demo 里的 SoC 其 I-Memory 是放在 Core 外面，通过 bus 读取指令的
   ![](https://s2.loli.net/2023/06/30/RE5kzTPf7BGt2iO.png)

2. I-Memory 架构不同，我们是 2Bank，demo 是 1-bank，
   因此加载 bin 文件的逻辑不同（NEMU 通过 xx 函数载入 bin 文件到其内存中）

   ![image-20230701083353042](https://s2.loli.net/2023/07/01/8Nzq52hxLsHiEPG.png)

   NEMU 加载镜像的过程如下：

   - NMEU 从`init_monitor`这个函数启动，在该函数内部：
     初始化一些 Log 信息，调调用 `init_mem` 函数、用 `init_isa` 函数、调用 `load_img` 函数
   - init_mem 函数主要负责加载默认的镜像文件到 I-Memory
     NEMU 的 I-Memory 有一块数组来表示，init_mem 函数主要的功能是给该数组赋值随机数

     ```c
       // paddr.c
       static uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};
       void init_mem() {
     
       ...
         srand(time(0));
         uint32_t *p = (uint32_t *)pmem;
         int i;
         for (i = 0; i < (int) (MEMORY_SIZE / sizeof(p[0])); i ++) {
           p[i] = rand();
         }
     ```

   - init_isa 函数主要负责载入默认镜像文件到 NEMU，并且初始化 pc 跟 x0 寄存器
     ![](https://s2.loli.net/2023/06/29/WeSfnj91rPyiZXu.png)
   - load_img 函数的主要功能是将镜像文件载入到 I-Memory 启示位置

     ```c
     // image_laoder.c
     long load_img(char* img_name, char *which_img, uint64_t load_start, size_t img_size) {
         ...
         FILE *fp = fopen(loading_img, "rb");
         Assert(fp, "Can not open '%s'", loading_img);
     
         size_t size;
         fseek(fp, 0, SEEK_END);
         size = ftell(fp);
         fseek(fp, 0, SEEK_SET);
         if (img_size != 0 && (size > img_size)) {
          Log("Warning: size is larger than img_size(upper limit), please check if code is missing. size:%lx img_size:%lx", size, img_size);
          size = img_size;
         }
     
         int ret = fread(guest_to_host(load_start), size, 1, fp);
     }
     // emu.cpp
       if (!strcmp(img + (strlen(img) - 4), ".bin")) {  // file extension: .bin
           FILE *fp = fopen(img, "rb");
           if (fp == NULL) {
               printf("Can not open '%s'\n", img);
               assert(0);
           }
     
           fseek(fp, 0, SEEK_END);
           img_size = ftell(fp);
           if (img_size > EMU_RAM_SIZE) {
               img_size = EMU_RAM_SIZE;
           }
     
           fseek(fp, 0, SEEK_SET);
           ret = fread(ram, img_size, 1, fp);
     
           assert(ret == 1);
           fclose(fp);
       }
     ```

   DUT 加载镜像的过程如下：

   - Emulator 构造函数会调用`init_mem`函数

     ![image-20230630175159241](https://s2.loli.net/2023/07/01/7wnKtoasHJedq6G.png)

   - `init_ram`函数会把 image bin 文件内容拷贝到`ram`这个指针所指代的地址

     ```c
     // ram.cpp
     static uint64_t *ram;
     //...
     void init_ram(const char *img) {
       assert(img != NULL);

       printf("The image is %s\n", img);

       // initialize memory using Linux mmap
       printf("Using simulated %luMB RAM\n", EMU_RAM_SIZE / (1024 * 1024));
       ram = (uint64_t *)mmap(NULL, EMU_RAM_SIZE, PROT_READ | PROT_WRITE, MAP_ANON | MAP_PRIVATE, -1, 0);
       if (ram == (uint64_t *)MAP_FAILED) {
         printf("Cound not mmap 0x%lx bytes\n", EMU_RAM_SIZE);
         assert(0);
       }
       //...
     }
     ```

   - ram.v 文件会通过 DPI-C 函数在访问 ram 指针所指的这块地址，实现`dut`读取指令

     ```verilog
     // ram.v
     import "DPI-C" function void ram_write_helper
     (
       input  longint    wIdx,
       input  longint    wdata,
       input  longint    wmask,
       input  bit        wen
     );
     
     import "DPI-C" function longint ram_read_helper
     (
       input  bit        en,
       input  longint    rIdx
     );
     
     module RAMHelper(
       input         clk,
       input         en,
       input  [63:0] rIdx,
       output [63:0] rdata,
       input  [63:0] wIdx,
       input  [63:0] wdata,
       input  [63:0] wmask,
       input         wen
     );
     
       assign rdata = ram_read_helper(en, rIdx); // 通过DPI-C读取指令
     
       always @(posedge clk) begin
         ram_write_helper(wIdx, wdata, wmask, wen && en); // 通过DPI-C写出指令
       end
     
     endmodule
     ```

   > 如果需要完成 MCU_core 的 I-Memory 初始化工作，需要“在 IF Stage 的 I-Memory 模块中添加 DPI-C 接口”，“更改 ram.cpp 文件里面的 init_mem 函数，以支持 2-bank ITCM”

# 下周计划

1. 按照上述问题原因，修改`ram.cpp`里加载指令到I-Memory里面的函数`init_ram`
2. 跑通difftest测试框架
3. 使用difftest框架测试riscv-tests指令集
