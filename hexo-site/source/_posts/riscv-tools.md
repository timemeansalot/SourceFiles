---
title: Unix 环境下，RISCV 工具链使用笔记
date: 2023-03-08 14:45:34
tags: RISCV
---

> Unix 环境下，RISCV 工具链使用笔记，包括如下内容：

1. RISCV 编译工具：gcc, objdump, ...
2. RISCV 调试工具：spike, pk, openOCD, GDB, llvm
3. RISCV assemble
4. Verilator: 编译工具，将 Verilog 编译成 C++文件和 Makefile, 结合 C++的 testbench，可以编译成可执行的测试文件

<!--more-->

# YouTube 开源学习资料

Contents to study:

- [x] RISCV Tutorial: Spike & Proxy Kernel from Source to Hello World
- [ ] RISCV Instruction and Assembly Tutorial
- [x] RISCV Assembly Tutorial: Practice with LED and Switch on Simulator
- [ ] RISCV Tutorial: Binary Instrumentation Technique using LLVM/CLANG Machine Instruction Pass
- [x] RISCV Tutorial: Running FEDORA on RISCV using QEMU
- [ ] RISCV Tutorial: How to Setup LLVM / CLANG for RISC-V
- [x] RISCV Tutorial: Spike Debugging, OpenOCD, GDB
- [x] RISCV Tutorial: Setup GCC Toolchain & SiFive Prebuilt Toolchain

## Tool Install

### RISCV GNU Toolchain

Linux 下有 2 种方法安装**编译工具链**：

1. 从[GitHub 克隆源代码](https://github.com/riscv-collab/riscv-gnu-toolchain)，然后按照 GitHub 中 readme 的步骤编译源代码，进行安装
2. 从[SiFive/freedom-tools](https://github.com/sifive/freedom-tools/releases)直接下载对应平台已经编译好的可执行文件，支持 Linux/Mac/Windows 等平台
   ![](https://s2.loli.net/2023/03/07/h5dNlWv3RjFTmXI.png)

安装完成之后，可以直接在终端中看到对应的工具：
![](https://s2.loli.net/2023/03/07/RVdZFGAjoOBY2az.png)

### 仿真工具：spike, pk, openocd, QEMU

1. [Spike](https://github.com/riscv-software-src/riscv-isa-sim)和[QEMU](https://github.com/qemu/qemu)都是模拟器，可以模拟 RISCV 指令的运行
2. [pk](https://github.com/riscv-software-src/riscv-pk) 是 proxy kernel，用于在 spike 中模拟一个简单的操作系统和 bbl，这样我们才可以加载程序到 spike 中模拟运行
3. [openocd](https://github.com/riscv/riscv-openocd) 是负责远程调试使用
4. [iverilog](https://github.com/steveicarus/iverilog): 免费开源的 Verilog 仿真工具，vcs 的平替

上述工具都可以在 GitHub 中下载对应的源代码，按照 readme 中的步骤编译安装。

### MacOS 下安装工具链和调试工具

macOS 下安装 riscv-gnu-toolchain，spike，pk 和 openocd 都可以[直接通过 homebrew 安装](https://github.com/riscv-software-src/homebrew-riscv):

```bash
brew tap riscv-software-src/riscv
# 安装工具链
brew install riscv-tools
brew install spike
brew install riscv-pk
brew install riscv-openocd
brew install icarus-verilog
```

测试是否安装成功: `brew test riscv-tools`, 该命令会测试工具链、riscv-isa-sim 和 riscv-pk.

> 总结: MacOS 下配置环境相比于 Linux 更加简单，直接使用 homebrew 就可以全部搞定。

## Spike 使用

### Spike 内部调试

1. 进入 Spike debug: `spike --isa=rv32im -d /user/local/bin/pk hello`
2. spike 内部 debug 命令：
   - `until 0 pc xx`: 一直运行到 pc=xx 的指令为止, 指令的地址可以搭配反汇编得到的汇编文件得到, 使用 objdump
   - `r 1`: 运行一条指令
   - `reg 0 a0`: 查看 core0 中寄存器 a0 的值

### 使用 openOCD 远程调试

参考[Debugging with Gdb](https://github.com/riscv-software-src/riscv-isa-sim#debugging-with-gdb).  
Spike <-> openOCD <-> GDB

# Verilator 使用笔记

> 使用 Verilog 编写好了一个功能单元和其测试文件 testbench，如何进行仿真呢？此时可以通过 Veriloator 将其转换为 C++文件，再编译得到可执行文件，就可以运行进行仿真啦。

## Verilog 的功能

对应的 alu.sv 文件和 tb_alu.cpp 文件可以在[该网页](https://itsembedded.com/dhd/verilator_1/)中找到。

1. 将 Verilog/SystemVerilog 文件转化为 C++的.h 文件和.cpp 文件以及 Makefile
   ```bash
   verilator -Wall --trace -cc alu.sv --exe tb_alu.cpp
   ```
   This converts our alu.sv source to C++ and generates build files for building the simulation executable. We use -Wall to enable all C++ errors, --trace to enable waveform tracing, -cc alu.sv to convert our alu.sv module to C++, and --exe tb_alu.cpp to tell Verilator which file is our C++ testbench.
2. 通过编译该 Makefile 可以得到可执行的文件，运行该可执行文件可以得到仿真的结果和波形
   ```bash
   make -C obj_dir -f Valu.mk Valu
   ./obj_dir/Valu
   ```
3. 打开波形
   ```bash
   gtkwave waveform.vcd
   ```
   > Verilator 只有 0，1 两种状态，没有 X 和 Z 状态

## UVM 测试

[UVM 测试](https://itsembedded.com/dhd/verilator_4/)是更加标准的测试，将 tb 文件分成 4 个模块：

1. input driver: 负责生成 dut 的输入数据流;  
   input driver 的输入数据来自于 sequence generator: 负责随机地生产测试数据，用于 input driver 往 dut 里输入数据
2. input monitor：负责收集输入数据流并且保存到 scoreboard
3. output monitor：负责收集输出数据流并且传到 scoreboard
4. scoreboard：接受 input monitor 传输到输入数据流，保存到一个队列中；收到 output monitor 的数据流时，跟队列头部保存的数据流做比较，如果匹配则一次测试通过、否则测试不通过

# iverilog 使用

[Icarus Verilog Tutorial](https://gist.github.com/donn/d9ecf0cf6e7ae3d99c7c4395e7e10afa)

1. 编译文件：`iverilog -o <filename>.vvp <testbench-name>.v`
2. 运行文件：`vvp <filename>.vvp`
3. 查看波形：`gtkwave xx.vcd`

# 总结

1. 当需要快速验证一个模块的时候，可以使用 iverilog，因为它只需要编写 dut 和 tb 即可.
2. 当需要验证比较大的模块的时候，还是使用 verilator+UVM 的方式，因为它虽然前期需要编写比较复杂的 c++ testbench，但是扩展性和自动化比较强。
3. 此外：使用 Chisel Test 来验证 Chisel 编写的硬件模块，则更加的高级，还可以配合 difftest 使用。
4. Spike 模拟器可以配合 RISCV 汇编代码使用，当我们不了解 RISCV 指令细节的时候，可以通过 Spike 运行对应的指令，然后查看结果。

# Referrences

1. [RISCV Tutorial on Youtube by Derry Pratama](https://www.youtube.com/watch?v=zZUtTplVHwE&list=PLgzAvj2cYr3qGvecT_PSnKzl5SxECZmI3)
2. [Veriloator Guide by Norbert](https://www.itsembedded.com/), Norbert also gives guide on [how to use vivado](https://itsembedded.com/dhd/vivado_sim_1/)
3. [Icarus Verilog Tutorial](https://gist.github.com/donn/d9ecf0cf6e7ae3d99c7c4395e7e10afa)
