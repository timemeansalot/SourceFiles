---
title: RISC-V编译和验证
date: 2023-05-22 11:42:06
tags: RISC-V
---

riscv-tests 和 verification

[TOC]

<!--more-->

## 调试理论(debug theory)

1. 需求 -> 设计 -><u> 代码 -> Fault -> Error -> Failure</u>
2. 两类 Bug
   1. 第一类 bug，实现跟需求不符合：解决的唯一办法是“仔细多次阅读需求”，保证需求理解正确  
      少看几句话，可能需要调试好几天
   2. 第二类 bug，代码实现跟需求不一致
3. 第二类 bug 中相关的三种“错误”

   1. Fault - 有 bug 的代码, 例如数组访问越界
   2. Error - 程序运行时刻的非预期状态, 如某些内存的值被错误改写
   3. Failure - 可观测的致命结果, 如输出乱码/assert 失败/段错误

   > 调试：从 Failure 回溯到 Fault 的过程，距离越远调试越困难

### 专业的调试方法

1. 添加断言(assert), <u>**把 Error 转变成 Failure**</u>：尽可能通过 assert 让 Error 变成可以观测到的 Failure

   - 把需求(specification)直接写出来, 运行时检查
   - 断言背后就是一个 if 语句，关键是条件

   ```c++
       if (!cond) {
           // observable failure
           report_and_exit();
       }
   ```

2. 进行测试, <u>**把 Fault 转变成 Error**</u>：尽可能地运行到 Fault 所在的代码

   - 单元测试(例如测试 decoder)，与具体模块相关，一般自行编写单元测试
   - 集成测试(例如测试 mcu core)，一些测试用例、<u>🌟[ riscv-tests ](https://github.com/riscv-software-src/riscv-tests)</u>
   - 随机测试：随机产生测试用例
     - [riscv-torture](https://github.com/ucb-bar/riscv-torture)
     - 好处：不用自己编写测试用例（编写测试用例很累）
     - 坏处：对于边界条件的覆盖不是很好，需要添加一些规则进行测试用例生成时的指导
   - 🌟[ Difftest ](https://github.com/OpenXiangShan/Difftest)，<u>属于最高级的"step and compare"类型的验证方法</u>

3. 用 lint 工具检查代码, <u>**暴露 Fault**</u>：使用编译工具在对代码做静态分析，暴露一些可能存在的 Fault

   - -Wall, -Werror
   - gcc，verilator，综合工具都可以对代码进行检测，报告 warning
   - 规范的芯片设计流程一定要清除工具报告的所有 warning

4. 编写可读, 可维护, 易验证的代码(不言自明, 不言自证)：<u>**防御性编程，采用不容易出 Fault 的编程方式**</u>

   - 从源头消灭 bug
   - 相比于手动编写 rtl，使用工具生成 rtl 会更加避免错误的产生

   ![defensive programming](https://s2.loli.net/2023/06/07/nZPKweCO7q4tuSA.png)

## Difftset

![Difftest basic verification frame](https://s2.loli.net/2023/06/07/Uum3NIOfts6JAbd.png)

1. 对 CPU 进行调试，可能的 Failure：结果错误、卡死
2. 对 CPU 进行调试的难点：

   1. 如何定位到**第一条**出错的指令、地方
   2. 如果不能定位到第一条出错的指令，则：

      - 最开始的 Failure 可能发生扩散，导致后续更大的 Failure
      - 最后反推第一条 Failure 十分困难

      > 思考：能否在每一条指令后面增加一个 assert，这样任何一条指令如果产生了 Error，
      > 都可以在第一时间被暴露为 failure，从而可以捕捉到第一条导致 Failure 的指令

3. assert 时应该检查什么？
   电路视角的计算机 = 组合逻辑电路 + 时序逻辑电路 = 一个巨大状态机
   1. 我们可以检查计算机的状态!
   2. 状态 = 时序逻辑电路 = **<u>寄存器 + PC + 内存</u>**
4. 如何知道 CPU 正确的状态？
   1. 借鉴软件工程中 Difftest(differential testing)的思想
   2. 核心思想: 对于根据同一规范的两种实现, 给定相同的有定义的输入, 它们的行为应当一致
   3. 回到处理器设计: 对于根据 riscv 手册的两种实现, 给定相同的正确程序, 它们的状态变化应当一致
   4. 其中一种实现是我们设计的 CPU、另一种实现选择一种**简单的模拟机**就可以了
5. 与模拟器进行 Difftest

   1. 选择一个模拟器作为参考(REF): QEMU, Spike, NEMU
   2. 为模拟器添加如下的 API：
      ![simulator API](https://s2.loli.net/2023/06/07/QOnc4MG1vqJNLi3.png)
   3. 让仿真框架可以获得 CPU 的状态：寄存器 + PC + 内存 + 提交的指令数
      ![Difftest process](https://s2.loli.net/2023/06/07/NltaFxfTmCyzwLS.png)
   4. 对模拟器的状态跟 CPU 状态进行比较

6. 验证普通指令

   1. 处理器将提交指令数、寄存器堆状态、PC 提交给 Difftest
   2. 模拟器执行相同数量的指令
   3. 比较处理器和模拟器的寄存器堆状态、PC

   ![](https://s2.loli.net/2023/06/07/AlNCBKkZj1Y8wOT.png)

7. 验证特殊情况下的指令
   1. 模拟器无法仅靠自己在一些行为上与正确的处理器<u>**对齐**</u>
   2. 无法依靠模拟器直接验证处理器的行为，需要做额外的处理(手动对齐)
   3. MMIO(memory mapped IO)：
      - 模拟器不能模拟所有的外部设备，模拟器无法得知这些 load 指令的正确结果
        ![](https://s2.loli.net/2023/06/07/mFVX7jUxn8KPIgY.png)
      - 解决方法：处理器识别出这样的访存指令、将其结果复制到模拟器中、跳过该指令的比较
        ```scala
        if (dut.commit[i].skip) {
           proxy->get_regs(ref_regs_ptr);
           ref.csr.this_pc += dut.commit[i].isRVC ? 2 : 4;
           if (dut.commit[i].wen && dut.commit[i].wdest != 0) {
               ref_regs_ptr[dut.commit[i].wdest] = dut.commit[i].wdata;
           }
           proxy->set_regs(ref_regs_ptr); return;
        }
        ```
   4. 中断处理: 处理器检测到中断、处理器传出中断信息, 模拟器进入相同的处理流程
      ```scala
          if (dut.event.interrupt) {
              dut.csr.this_pc = dut.event.exceptionPC; do_interrupt();
          } else if(dut.event.exception) {
              dut.csr.this_pc = dut.event.exceptionPC; do_exception();
          } else {
              // 正常的处理流程
          }
      ```
8. Difftest 的优点

   1. 本质：在线指令级验证方法
      - 在线：边跑程序边验证
      - 指令级：对每一条指令功能进行验证
   2. 支持把任意程序转化为*指令级别的测试*
   3. 支持*不会结束的程序*
   4. 不用提前知道程序运行的结果：对比的是指令执行的行为, 而不是程序的语义
   5. riscv-torture 是离线验证，基于比较 signature，没有上述 Difftest 的优点

9. 为什么不自行维护模拟器，而是使用通用的模拟器？
   1. 现如今，处理器设计时更新迭代十分的迅速，在这种情况下要维护每一版处理器微架构对应的模拟器，
      一方面代码工作量很大、另一方面不满足敏捷开发的需求。
   2. 因此，如果要求处理器设计满足 riscv 手册的规范，我们只需要保证处理器跟模拟器在指令级层面的一致性即可，
      具体表现就是每一条指令执行之后，对应的“RF, CSR, PC 和内存”都一致。
10. 为什么采用 NEME 作为模拟器
    1. 代码复杂度：`NEMU < Spike << QEMU`
    2. 运行速度快
       ![](https://s2.loli.net/2023/06/07/EOIRelTfqA2MtWQ.png)
    3. 接口 API 提供
11. Difftest验证通过的标志
    1. 通过 Difftest 框架，能够运行结束指定的程序，不报错
    2. 通过 Difftest 框架，执行相当数量的随机指令流（几亿条）、或者执行不会结束的程序一段足够长的时间

## 接入 Difftest 框架

1. 为 Difftest 提供如下的目录结构：
   ```bash
   .
    ├── build
    │   └── SimTop.v // 处理器 verilog 源代码
    ├── Difftest // Difftest 仓库, 可以作为 submodule 引入
    └── ......
   ```
2. 配置 NEMU_HOME，Difftest 默认使用 NEMU 作为对比的模拟器
3. 在设计中将关键信号传递给 Difftest 框架

   1. Difftest 采用 DPI-C 来将仿真中的信号传递到 Difftest，框架中在仿真程序执行的过程中会调用 DPI-C 函数, 将 Difftest 感兴趣的信号写入到对应的结构体中.
   2. 需要传递的信息的最小子集包括: instrCommit, IntRegState, CSRState

   ```scala
   import Difftest._
    // ......

    class WBU {
      if (!env.FPGAPlatform) { // 只有在仿真时才需要 Difftest 的 module
        val Difftest = Module(new DifftestArchEvent)
        Difftest.io.clock := clock
        // ......
      }
    }
   ```

   3. 注意：乱序处理器在 commit 的时候、顺序处理器在 write back 的时候将信息传递给 Difftest 框架
      ![transfer data to Difftest at WB](https://s2.loli.net/2023/06/07/l1hs4mLfeiYN5IJ.png)
   4. 运行仿真，在线验证: `./build/emu -b 0 -e 0 -i ./ready-to-run/coremark-2-iteration.bin`
      ![](https://s2.loli.net/2023/06/07/RPvWopz4nrOIJ2V.png)

## 参考资料

1. [Difftest: detailed usage (Chinese)](https://github.com/OpenXiangShan/Difftest/blob/master/doc/usage.md)
2. [Example: Difftest in XiangShan project (Chinese)](https://github.com/OpenXiangShan/Difftest/blob/master/doc/example-xiangshan.md)
3. [Example: Difftest in NutShell project (Chinese)](https://github.com/OpenXiangShan/Difftest/blob/master/doc/example-nutshell.md)
4. [crvf2019: The First China RISC-V Forum](https://github.com/crvf2019/crvf2019.github.io)
5. [香山的官方文档仓库](https://github.com/OpenXiangShan/XiangShan-doc)

## 请各位老师同学，批评指正
