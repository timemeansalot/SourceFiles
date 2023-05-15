---
title: 面试笔记
date: 2023-05-15 08:50:17
tags: IC
---

一些面试笔记

<!--more-->

### 原码、反码、补码

以 8 进制的数为例

1. 原码
   - 表示范围: -127, 127
   - 000000000, 10000000 都表示 0
2. 反码
   - 表示范围：-127，127
   - 000000000, 11111111 都表示 0
3. 补码
   - 表示范围：-128, 127
   - 000000000 表示 0，10000000 表示-128

### 竞争和冒险

> 元件是有时延的，导致信号达到各个部件的时间其实是不一致的

1. 竞争：信号达到各个部件之间的时间是不一样的，这就叫做竞争
2. 冒险：由于竞争导致电路产生的“瞬时的错误（毛刺）”

![glitch](https://s2.loli.net/2023/05/15/nVQfwYkRG1vFBZl.png)

### 用 D 触发器带同步高置数和异步高复位端的二分频的电路

```verilog
    reg Q;
    reg clk, reset, enable;
    always @(posedge clk or posedge reset) begin
        if(reset==1'b1) begin
            Q <= 1'b0;
        end
        else if(enable) begin
            Q <= 1'b1;
        end
        else begin
            Q <= ~Q;
        end
    end
```

![](https://s2.loli.net/2023/05/15/8ULWgrd12a9wGoi.png)

### CMOS 反相器的功耗主要包括哪几部分

$P_{avg}$=$P_{dynamic}$+$P_{static}$=($P_{short}$+$P_{switch}$)+$P_{static}$=$I_{sc}$$V_{dd}$+$\alpha$$C_{L}$$V_{dd}^{2}$f+$I_{leak}$$V_{dd}$

![cmos leakage](https://s2.loli.net/2023/05/15/BP64YAEoGXF1wtR.png)

### 最小时钟周期

![minimum T](https://s2.loli.net/2023/05/15/it9SeXy8KVERDHT.png)
$T_{min}=T_{co}+T_{data}+T_{su}+T_{skew}$

1. $T_{co}$: 寄存器更新延迟
2. $T_{data}$：信号在导线上传输的延迟
3. $T_{su}$: 第二个寄存器的 setup 时间
   $T_h$: 第二个触发器的 hold 时间
4. $T_{skew}$：时钟的延迟，clk 传到第二个寄存器需要更多的时间

> PS: clock jitter: 时钟周期由于晶振或者 PLL 内部电路导致不是固定的周期，与布局布线没有关系

### 亚稳态

![](https://pic1.zhimg.com/80/v2-52d7d442cc63a00330aaebe2d76f4b7c_720w.webp)

1. 定义: 触发器无法在某个规定时间段内达到一个确定的状态
2. 原因：由于触发器的 Tsu 和 Th 不满足，当触发器进入亚稳态，使得无法预测该单元的输出，这种不稳定 是会沿信号通道的各个触发器级联传播
3. 消除：两级或多级寄存器同步。理论上亚稳态不能完全消除，只能降低，一般采用两级触发器同步就可 以大大降低亚稳态发生的概率，再加多级触发器改善不大  
   如果一个触发器进入正常的概率是 P，则 N 个触发器亚稳态的概率是 NP
4. 亚稳态窗口：setup + hold
   当寄存器性能好，其 setup time 和 hold time 都会更短，因此亚稳态窗口也更窄

### localparam、parameter 和 define

1. localparam: 只在当前的 verilog 文件里有效
2. parameter: 在当前文件和上层文件里都有效
3. define：define 定义的变量从编译器读到这条语句开始，到编译结束（或者到 undefine 语句结束）
