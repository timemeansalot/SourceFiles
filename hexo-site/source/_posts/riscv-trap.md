---
title: RISCV 异常和中断
date: 2023-03-23 14:58:33
tags: RISCV
---

RISCV 异常和中断

<!--more-->

[TOC]

## RISCV Exception & Interrupt

RISCV 特权等级：

| Level | Encoding | Name             | Abbreviation |
| ----- | -------- | ---------------- | ------------ |
| 0     | 00       | User/Application | U            |
| 1     | 01       | Supervisor       | S            |
| 2     | 10       | Reserved         |              |
| 3     | 11       | Machine          | M            |

RISCV 支持的特权模式组合：

| 组合序号 | 支持的模式 | 应用场景                           |
| -------- | ---------- | ---------------------------------- |
| 1        | M          | 简单的嵌入式系统                   |
| 2        | M, U       | 有安全支持的嵌入式系统             |
| 3        | M, S, U    | 能跑操作系统如 Linux(支持虚拟内存) |

### CSR 指令

| CSR 指令格式 | 31, 20    | 19, 15       | 14, 12 | 11, 7 | 6, 0    |
| ------------ | --------- | ------------ | ------ | ----- | ------- |
|              | CSR       | rs1          | funct3 | rd    | opcode  |
| `CSRRW`      | CSR Index | source       | 001    | rd    | 1110011 |
| `CSRRS`      | CSR Index | source       | 010    | rd    | 1110011 |
| `CSRRC`      | CSR Index | source       | 011    | rd    | 1110011 |
| `CSRRWI`     | CSR Index | unsigned imm | 101    | rd    | 1110011 |
| `CSRRSI`     | CSR Index | unsigned imm | 110    | rd    | 1110011 |
| `CSRRCI`     | CSR Index | unsigned imm | 111    | rd    | 1110011 |

| 指令         | 说明                                                                                                                                      | 数学表达                                                                       |
| ------------ | ----------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| CSRRW(Write) | 取出 csr 寄存器里的值，零拓展为 32 位后存到 rd 寄存器里；将 rs1 寄存器里的值存到 crs 寄存器里                                             | $x[rd]=zeroExt(crs[index]),\\ csr[index] = x[rs1]$                             |
| CSRRS(Set)   | 取出 csr 寄存器里的值，零拓展为 32 位后存到 rd 寄存器里；若 rs1 寄存器里某一位是 1，则将 crs 寄存器对应位<u>置 1</u>，负责 csr 对应位不变 | $x[rd]=zeroExt(crs[index]),\\ csr[index]                    \| = x[rs1]$       |
| CSRRC(Clear) | 取出 csr 寄存器里的值，零拓展为 32 位后存到 rd 寄存器里；若 rs1 寄存器里某一位是 1，则将 crs 寄存器对应位<u>清零</u>，负责 csr 对应位不变 | $x[rd]=zeroExt(crs[index]),\\ csr[index]\&= !x[rs1]$                           |
| CSRRWI       | 将 rs1 寄存器替换成无符号立即数                                                                                                           | $x[rd]=zeroExt(crs[index]),\\ csr[index] = zeroExt(imm)$                       |
| CSRRSI       | 将 rs1 寄存器替换成无符号立即数                                                                                                           | $x[rd]=zeroExt(crs[index]),\\ csr[index]                    \| = zeroExt(imm)$ |
| CSRRCI       | 将 rs1 寄存器替换成无符号立即数                                                                                                           | $x[rd]=zeroExt(crs[index]),\\ csr[index]\&= !zeroExt(imm)]$                    |

### Trap 相关控制寄存器

#### Trap Setup:

| 寄存器  | 描述                                                                                                  | 长度 |
| ------- | ----------------------------------------------------------------------------------------------------- | ---- |
| mstatus | 跟踪和控制 hart 的当前运行状态                                                                        | XLEN |
| mtvec   | (trap vector base address): 表明 trap 发生的时候，PC 需要跳转的地址                                   | XLEN |
| mie     | (interrupt enable): 用于进一步控制（打开和关闭）software interrupt/timer interrupt/external interrupt | XLEN |

![mstatus](/Users/fujie/Pictures/typora/csr/mstatus.jpg)
`mstatus`寄存器中的:

- `xIE`字段用于控制全局中断使能；高级模式的中断关闭之后，比它等级低的中断都会关闭、低级模式的中断打开之后，比它等级高的中断都会打开
- `xPIE`(previous interrupt enable)字段用于存储 trap 发上之前 hart 的中断使能
- `xPP`(previous privilege)字段存储进入 trap 之前 hart 所处的特权模式

![mtvec](/Users/fujie/Pictures/typora/csr/mtvec.jpg)
`mtvec`寄存器中的:

- `BASE`字段必须是 4byte 对齐
- `MODE`

  - 0 for direct: `pc=BASE`
  - 1 for vectored: `pc=BASE+4*cause`,
    例：当**machine time interrupt**发生的时候，已知其对应的 mcause=111，故`pc=BASE+(111<<2)=BASE+0x1C`
  - $\ge 2$: Reserved

  > PS: RISCV 中的指令都是 little endian

![mie](/Users/fujie/Pictures/typora/csr/mie.jpg)
![mie](/Users/fujie/Pictures/typora/csr/miestandard.jpg)
`mie`(ie for interrupt enable)寄存器中的每 bit 指定 mcause 中的各种类型的 trap 是否打开

#### Trap Handling:

| 寄存器   | 描述                                                                          | 长度 |
| -------- | ----------------------------------------------------------------------------- | ---- |
| mcause   | (trap cause): 记录导致 trap 的原因                                            | XLEN |
| mtval    | (trap value): 补充 trap 发生 的额外信息                                       | XLEN |
| mepc     | (exception pc): 保存 trap 发生时的 PC 到该寄存器里, 32 处理器下其 lsm[1:0]=00 | XLEN |
| mip      | (interrupt pending): 它列出目前已发生等待处理的中断                           | XLEN |
| mscratch | (scratch): 一般用于指向某 M 模式的上下文空间                                  | XLEN |

![mip](/Users/fujie/Pictures/typora/csr/mip.jpg)
![mipstandard](/Users/fujie/Pictures/typora/csr/mipstandard.jpg)
`mip`(ip for interrupt pending)寄存器中的每 bit 判断 mcause 中的各种类型的 trap 是否 pending

![mcause](/Users/fujie/Pictures/typora/csr/mcause.jpg)
`mcause`最高位=1，表明 trap 是 interrupt，否则 trap 是 exception

#### Time/Counter

| 寄存器   | 描述                                                        | 长度 |
| -------- | ----------------------------------------------------------- | ---- |
| mcycle   | (machine cycle counter): 记录该 hard 运行的 cycle 数        | 64   |
| minstret | (machine instruction retired counter): 记录执行完毕的指令数 | 64   |
| mtime    | M 模式按时自增的计时器                                      | 64   |
| mtimecmp | 比较计时器，当 mtime$/ge$mtimecmp 时会触发 timer interrupt  | 64   |

### Trap 类型

> Trap 类型有`mcause`寄存器指出，其中最高位为 1 表明是 interrupt，为 0 表示是 exception

| Interrupt                                                                                                                                           | Exception Code                                                                                                                                                                            | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| --------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1<br />1<br />1<br />1                                                                                                                              | 0<br />1<br />2<br />3                                                                                                                                                                    | Reserved<br /> Supervisor software interrupt<br /> Reserved<br /> Machine software interrupt                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| 1<br />1<br />1<br />1                                                                                                                              | 4<br />5<br />6<br />7                                                                                                                                                                    | Reserved<br /> Supervisor timer interrupt<br /> Reserved<br /> Machine timer interrupt                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| 1<br />1<br />1<br />1                                                                                                                              | 8<br />9<br />10<br />11                                                                                                                                                                  | Reserved<br /> Supervisor external interrupt<br /> Reserved<br /> Machine external interrupt                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| 1<br />1                                                                                                                                            | 12–15<br /> ≥16                                                                                                                                                                           | Reserved<br /> Designated for platform use                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| 0<br />0<br />0<br />0<br />0<br />0<br />0<br />0<br />0<br />0<br />0<br />0<br />0<br />0<br />0<br />0<br />0<br />0<br />0<br />0<br />0<br /> | 0<br /> 1<br /> 2<br /> 3<br /> 4<br /> 5<br /> 6<br /> 7<br /> 8<br /> 9<br /> 10<br /> 11<br /> 12<br /> 13<br /> 14<br /> 15<br /> 16–23<br /> 24–31<br /> 32–47<br /> 48–63<br /> ≥64 | Instruction address misaligned<br /> Instruction access fault<br /> Illegal instruction<br /> Breakpoint <- `EBREAK`<br /> Load address misaligned<br /> Load access fault<br /> Store/AMO address misaligned<br /> Store/AMO access fault <br /> Environment call from U-mode <- `ECALL`<br /> Environment call from S-mode <- `ECALL`<br /> Reserved<br /> Environment call from M-mode <- `ECALL`<br /> Instruction page fault<br /> Load page fault<br /> Reserved<br /> Store/AMO page fault<br /> Reserved<br /> Designated for custom use<br /> Reserved<br /> Designated for custom use<br /> Reserved |

1. Illegal Instruction Exception:
   - 访问不存在的 CSR
   - Write to read only CSR
   - 低特权级别尝试访问高级别的 CSR

通过上表可以看出：

- interrupt 主要有三种，分别是：`software interrupt`, `timer interrupt`和`external interrupt`，在三种模式`M`, `S`, `U`下都有对应的 interrupt.
- exception 主要有五种，分别是：`instruction`, `load/store`, `environment call`, `page fault`和`breakpoint`  
  exception 的优先级从上到下依次递减，如果同时发生了多个 exception，则优先级高的被处理

| Priority | Exc. Code                            | Description                                                                                                                                     |
| -------- | ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| Highest  | 3                                    | Instruction address breakpoint                                                                                                                  |
|          | 12, 1                                | During instruction address translation:First encountered page fault or access fault                                                             |
|          | 1                                    | With physical address for instruction:Instruction access fault                                                                                  |
|          | 2<br />0<br />8, 9, 11<br />3<br />3 | Illegal instruction<br /> Instruction address misaligned<br /> Environment call<br /> Environment break<br /> Load/store/AMO address breakpoint |
|          | 4, 6                                 | Optionally:Load/store/AMO address misaligned                                                                                                    |
|          | 13, 15, 5, 7                         | During address translation for an explicit memory access:First encountered page fault or access fault                                           |
|          | 5, 7                                 | With physical address for an explicit memory access:Load/store/AMO access fault                                                                 |
| Lowest   | 4, 6                                 | If not higher priority:Load/store/AMO address misaligned                                                                                        |

### Trap 处理流程

<img src="/Users/fujie/Pictures/typora/csr/trap_procedure.jpg" alt="trap_procedure" style="zoom:50%;" />
1. 初始化: 将trap_vector的地址存储到`mtvec`，这样当trap发生的时候，pc可以自动跳转到该地址去执行trap处理程序
    ```S
      trap_vector:
        # save context(registers).
        csrrw	t6, mscratch, t6	# swap t6 and mscratch
        reg_save t6

        # Save the actual t6 register, which we swapped into
        # mscratch
        mv	t5, t6		# t5 points to the context of current task
        csrr	t6, mscratch	# read t6 back from mscratch
        sw	t6, 120(t5)	# save t6 with t5 as base

        # Restore the context pointer into mscratch
        csrw	mscratch, t5

        # call the C trap handler in trap.c
        csrr	a0, mepc
        csrr	a1, mcause
        call	trap_handler # call C functions to solve trap

        # trap_handler will return the return address via a0.
        csrw	mepc, a0

        # restore context(registers).
        csrr	t6, mscratch
        reg_restore t6

        # return to whatever we were doing before trap.
        MRET

    ```

2. TOP Half, 一些硬件自动做的工作，更新 csr 的信息
   - 针对`mstatus`: $MPIE=MIE, MIE=0$
   - 如果 trap 是 interrupt 则`mepc=pc+1`; 如果 trap 是 exception 则`mepc=pc`
   - <u>`pc=mtvec`</u>
   - 根据 trap 发生之前所处的特权等级去设置`mstatus`的 MPP 字段，进入到 M 模式
3. Botton Half: 执行 trap_handler

   - 保存（save）当前控制流的上下文信息（利用 mscratch）
   - 调用 C 语言的 trap_handler
   - 从 trap_handler 函数返回， mepc 的值有可能需要调整
   - 恢复（restore）上下文的信息
   - 执行 MRET 指令返回到 trap 之前的状态。

   ```c
      reg_t trap_handler(reg_t epc, reg_t cause)
      {
        reg_t return_pc = epc;
        reg_t cause_code = cause & 0xfff;

        if (cause & 0x80000000) {
          /* Asynchronous trap - interrupt */
          switch (cause_code) {
          case 3:
            uart_puts("software interruption!\n");
            break;
          case 7:
            uart_puts("timer interruption!\n");
            break;
          case 11:
            uart_puts("external interruption!\n");
            break;
          default:
            uart_puts("unknown async exception!\n");
            break;
          }
        } else {
          /* Synchronous trap - exception */
          printf("Sync exceptions!, code = %d\n", cause_code);
          panic("OOPS! What can I do!");
          //return_pc += 4;
        }
        return return_pc;
      }
   ```

4. 返回：执行 xRET 指令
   - 在不同特权模式下退出有对应的 ret 指令，如: mret, sret, uret
   - mret 硬件将会执行如下操作：
     - 更改当前 hart 的特权模式为 mstatus.MPP
     - `mstatus.MIE=mstatus.MPIE, mstatus.MPIE=1`
     - <u>`pc=mepc`</u>

![csr_demo](/Users/fujie/Pictures/typora/csr/csr_demo.jpg)

## References

1. [The RISC-V Instruction Set Manual Volume I: Unprivileged ISA, Chapter 9 “Zicsr”, Control and Status Register (CSR)](https://five-embeddev.com/riscv-isa-manual/latest/csr.html)
2. [The RISC-V Instruction Set Manual Volume II: Privileged Architecture, Chapter 3 Machine-Level ISA](https://www.five-embeddev.com/riscv-isa-manual/latest/machine.html)
3. [Writing a RISC-V Emulator in Rust: Control and Status Register](https://book.rvemu.app/hardware-components/03-csrs.html#:~:text=RISC%2DV%20calls%20the%206,5%2Dbit%20zero%2Dextended.)
4. [RISC-V Bytes: Privilege Levels](https://danielmangum.com/posts/risc-v-bytes-privilege-levels/)
