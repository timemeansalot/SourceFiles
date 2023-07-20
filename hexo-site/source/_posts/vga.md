---
title: VGA笔记
date: 2023-07-10 11:16:32
tags:
  - RISC-V
  - IP
password: opensource
---

VGA相关笔记

![img](https://imgconvert.csdnimg.cn/aHR0cHM6Ly9pbWcyMDE4LmNuYmxvZ3MuY29tL2Jsb2cvMTQyNjI0MC8yMDE4MDkvMTQyNjI0MC0yMDE4MDkyMjE2MzI1MTM0My0yMjkzOTAwNjkuanBn?x-oss-process=image/format,png)

<!--more-->

[TOC]

# VGA（Video Graphics Array）基础原理

> 实际上，操作VGA的过程就是给你一块有横纵坐标范围的区域，区域上的每一个坐标点就是一个像素点，你可以做的事情是**给这个像素点特定的rgb色彩**.

## 历史背景

1.  IBM于1987年随PS/2机一起推出的一种使用模拟信号的视频传输标准

2.  不支持热插拔，不支持音频传输

3.  信号：三原色（红绿蓝）、hsync、vsyn

4.  时序

    ![VGA时序](https://s2.loli.net/2023/07/13/bLzAfZvM8YgURuo.png)

    Hor Scan Time是一个扫描周期，它会先扫描到Hor Sync、再扫描Hor Back Porch，然后才进入有效显示区Hor Active Video，最后是一段Hor Front Porch；可以看出来，四段区间只有Hor Active Video这一段是能够正常显示图像信息的，也就是屏幕上显示的那一块区间

    VGA的时序参数跟**分辨率**以及**刷新频率**有关

    - 分辨率

      ![image-20230711113651677](https://s2.loli.net/2023/07/13/F8OE2iUr74nHxuK.png)

    - 刷新频率：行扫描周期 _ 场扫描周期 _ 刷新频率 = 时钟频率

           640x480@60：
           行扫描周期：800(像素)，场扫描周期：525(行扫描周期) 刷新频率：60Hz
           800 _ 525 _ 60 = 25,200,000 ≈ 25.175MHz （误差忽略不计）
           640x480@75：
           行扫描周期：840(像素) 场扫描周期：500(行扫描周期) 刷新频率：75Hz
           840 _ 500 _ 75 = 31,500,000 = 31.5MHz

           ![VESA and Industry Standards and Guidelines

      for Computer Display Monitor Timing (DMT)](https://s2.loli.net/2023/07/13/c5HDeym6pquUBYT.png)

5.  VGA基础知识

    1. 一件很重要的事情是，虽然你看到的屏幕大小是640x480的，但是它的实际大小并不只有那么点，形象一点就是说，VGA扫描的范围是包含了你能够看到的640x480这一块区域的更大区域
    2. VGA 显示器扫描方式从屏幕左上角一点开始，从左向右逐点扫描，每扫描完一行，电子束回到屏幕的左边下一行的起始位置，在这期间，**CRT（阴极射线管） 对电子束进行消隐**（当电子枪扫描过了右侧没有荧光粉的区域后，还没有收到回到最左侧的命令（行同步信号脉冲）之前，电子枪需要关闭以实现**消隐**），每行结束时，用行同步信号进行同步
    3. 当扫描完所有的行，**形成一帧**，用场同步信号进行场同步，并使扫描回到屏幕左上方
    4. 完成一行扫描的时间称为水平扫描时间，其倒数称为行频率；完成一帧（整屏）扫描的时间称为垂直扫描时间，其倒数称为场频率，即屏幕的刷新频率

    ![img](https://imgconvert.csdnimg.cn/aHR0cHM6Ly9pbWcyMDE4LmNuYmxvZ3MuY29tL2Jsb2cvMTQyNjI0MC8yMDE4MDkvMTQyNjI0MC0yMDE4MDkyMjE2MzM0NTgxOC0xNzA0NjU5OTQucG5n?x-oss-process=image/format,png)

# VGA开源项目

## [vga-clock](https://github.com/mattvenn/vga-clock)

> 在640x480 VGA 显示器上显示时间的简单项目

![image-20230712192126069](https://s2.loli.net/2023/07/13/lJLxqWwBAD49j2F.png)

只实现了**640x480**分辨率的VGA Controller，然后基于该VGA Controller实现了*时钟显示的应用*

| 考核标准   |     |
| ---------- | --- |
| 可读性     | 4   |
| 可配置性   | 2   |
| 功能正确性 | 5   |
| 易用性     | 2   |

## [Miz702_VGA](https://gitee.com/fengshuaigit/Miz702_VGA)

> 支持640\*480分辨率，能够显示静态彩色图片

其VGA控制器端口如下，控制器端口列表里不包括待显示的数据信号，一共可以显示640x480个像素点，像素点位置由pixel_x, pixel_y确定

```verilog
module vga_sync(
        input   wire            clk,
        input   wire            rst_n,
        output	wire		video_en,                  //数据有效
        output  reg             hsync,                 //场同步信号
        output  reg             vsync,                 //行同步信号
        output  wire    [9:0]   pixel_x,               //待显示待像素的x坐标
        output  wire    [9:0]   pixel_y                //待显示待像素的y坐标
);

endmodule
```

测试文件的端口如下所示，测试文件端口里不包含像素点的坐标信息，因为连接到显示器之后，VGA信号会自动从左到右、从上到下在显示器上输出显示，在确定了显示的分辨率跟频率之后，信号输出的位置由`hsync`跟`vsync`信号确定

```verilog
module vga_test(
            input   wire            sys_clk,
            input   wire            sys_rst_n,
            output  wire            hsync,  // <-- VGA port 13
            output  wire            vsync,  // <-- VGA port 14
    		output  wire   [11:0]   rgb,    // <-- VGA port 1,2,3
		    output  reg	            led
);
endmodule
```

在显示器上输出静态图片的原理：

- 将640x480的静态图片制作成ceo文件
- 在vivado里将该ceo文件创建为一个ROM IP
- 在testbench里面调用该ROM IP，实现数据读取。将数据读取到寄存器里
- testbench输出rbg信号的时候，存寄存器里输出信号到rgb

项目分析（满分5分）：

| 考核标准   |     |
| ---------- | --- |
| 可读性     | 5   |
| 可配置性   | 2   |
| 功能正确性 | 5   |
| 易用性     | 4   |

## [VGA原理与FPGA实现](https://blog.csdn.net/yifantan/article/details/126835530?utm_medium=distribute.pc_relevant.none-task-blog-2~default~baidujs_baidulandingword~default-5-126835530-blog-81840978.235^v38^pc_relevant_sort_base2&spm=1001.2101.3001.4242.4&utm_relevant_index=8)

> 支持多种分辨率

其VGA Controller端口定义如下，Controller端口里包含了数据信号的输入、输出`Data`, `VGA_RGB`

```verilog
module VGA_CTRL(
    input Clk,
    input Reset_n,
    input [23:0]Data,
    output reg Data_Req,    //根据波形调试得到
    output reg [9:0]hcount, //当前扫描点的有效图片H坐标, 用于test模块
    output reg [9:0]vcount, //当前扫描点的有效图片V坐标, 用于test模块
    output reg VGA_HS,
    output reg VGA_VS,
    output reg VGA_BLK,     //BLK表示的就是 输出有效图片 信号  高电平有效
    output reg [23:0]VGA_RGB//  RGB888
    );
endmodule
```

所有支持的分辨率在一个文件里定义，通过宏的方式选择某一个分辨率

```verilog
// `define Resolution_480x272 1	//刷新率为60Hz时像素时钟为9MHz
`define Resolution_640x480 1	//刷新率为60Hz时像素时钟为25.175MHz
// `define Resolution_800x480 1	//刷新率为60Hz时像素时钟为33MHz
//`define Resolution_800x600 1	//刷新率为60Hz时像素时钟为40MHz
//`define Resolution_1024x768 1	//刷新率为60Hz时像素时钟为65MHz
//`define Resolution_1280x720 1	//刷新率为60Hz时像素时钟为74.25MHz
//`define Resolution_1920x1080 1	//刷新率为60Hz时像素时钟为148.5MHz

`ifdef Resolution_480x272
    `define H_Right_Border 0
    `define H_Front_Porch 2
    `define H_Sync_Time 41
    `define H_Back_Porch 2
    `define H_Left_Border 0
    `define H_Data_Time 480
    `define H_Total_Time 525
    `define V_Bottom_Border 0
    `define V_Front_Porch 2
    `define V_Sync_Time 10
    `define V_Back_Porch 2
    `define V_Top_Border 0
    `define V_Data_Time 272
    `define V_Total_Time 286

`elsif Resolution_640x480
	`define H_Total_Time  12'd800
	`define H_Right_Border  12'd8
	`define H_Front_Porch  12'd8
	`define H_Sync_Time  12'd96
	`define H_Data_Time 12'd640
	`define H_Back_Porch  12'd40
	`define H_Left_Border  12'd8
	`define V_Total_Time  12'd525
	`define V_Bottom_Border  12'd8
	`define V_Front_Porch  12'd2
	`define V_Sync_Time  12'd2
	`define V_Data_Time 12'd480
	`define V_Back_Porch  12'd25
	`define V_Top_Border  12'd8

//......
```

在VGA_CTRL模块里，调用了各种分辨率对应的宏，从而支持各种分辨率的VGA

```verilog
    localparam Hsync_End = `H_Total_Time;
    localparam HS_End = `H_Sync_Time;
    localparam Hdat_Begin = `H_Sync_Time + `H_Back_Porch + `H_Left_Border;
    localparam Hdat_End = `H_Sync_Time + `H_Left_Border + `H_Back_Porch + `H_Data_Time;
    localparam Vsync_End = `V_Total_Time;
    localparam VS_End = `V_Sync_Time;
    localparam Vdat_Begin =  `V_Sync_Time + `V_Back_Porch + `V_Top_Border;
    localparam Vdat_End = `V_Sync_Time + `V_Back_Porch + `V_Top_Border + `V_Data_Time;
```

项目分析（满分5分）：

| 考核标准   |     |
| ---------- | --- |
| 可读性     | 5   |
| 可配置性   | 4   |
| 功能正确性 | 5   |
| 易用性     | 4   |

![image-20230713110232004](https://s2.loli.net/2023/07/13/tYG5xCX3ypM6F8L.png)

![image-20230713110138494](https://s2.loli.net/2023/07/13/rHQUsAGiDJP6ujf.png)

## [vga_lcd](https://github.com/freecores/vga_lcd)

<img src="https://s2.loli.net/2023/07/13/NFyegRCiTvaLcnl.png" alt="image-20230713113742671" style="zoom: 25%;" />

该项目有以下特点：

1. 支持多种分辨率、自定义分辨率
2. 支持多种颜色深度bpp
3. 定义了跟Host进行数据读取的模块
4. 支持鼠标模块

上述架构图中，各个模块的功能如下：

1. Cursor相关部分

   - Cursor Base Register：存储Cursor像素信息的起始地址
   - Cursor Buffer：从存储里读取出来的Cursor的信息，可以存储在该Buffer中，从而避免每次需要访问存储才能得到Cursor的像素信息。该Buffer的容量是512x32bit
   - Cursor Processor：负责计算跟Cursor相关的像素点的位置、颜色信息，需要跟VGA背景颜色进行选择，从而在屏幕上展示Cursor

2. 图像相关部分

   - Line FiFo：输入RBG信号，是一个ping pong memory的结构，保证了输出到VGA屏幕的颜色信号源源不断、同时起到时钟域切换的作用
   - Color Processor：将不同深度的颜色转化为VGA屏幕展示的RGB信息，当输入的颜色信息是32bit, 24 bit时，直接pass through即可；当输入颜色信息是16bit时，其中5bit展示红色、6bit展示绿色、5bit展示蓝色；当输入的颜色是8bit时，通过内部的Color Lookup Table找到RGB颜色
   - Video Timing Generator：产生VGA同步信号，如`VSYNC, HSYNC`

3. 数据访问相关

   - Video Memory Base Register：存储外部Video数据的起始地址
   - Wishbone Master Interface：Color Processor跟Cursor Processor访问外部存储器时，通过该接口
   - Wishbone Slave Interface：控制用户可以访问的寄存器的访问

项目分析（满分5分）：

| 考核标准   |     |
| ---------- | --- |
| 可读性     | 3   |
| 可配置性   | 5   |
| 功能正确性 | 5   |
| 易用性     | 3   |

# VGA项目比较

如上所述，[vga-clock](https://github.com/mattvenn/vga-clock)、 [Miz702_VGA](https://gitee.com/fengshuaigit/Miz702_VGA)两个项目都只支持固定640x480分辨率的VGA接口，其优点在于代码规范、比较容易上手；

[VGA原理与FPGA实现](https://blog.csdn.net/yifantan/article/details/126835530?utm_medium=distribute.pc_relevant.none-task-blog-2~default~baidujs_baidulandingword~default-5-126835530-blog-81840978.235^v38^pc_relevant_sort_base2&spm=1001.2101.3001.4242.4&utm_relevant_index=8)则支持多种分辨率模式的VGA接口，其原理在于通过预先定义的宏来支持各种分辨率的VGA，并且其VGA Controller模块中的信号包含`hsync, vsync, RGB[23:0]` 等信号，因此其VGA Controller的输出可以直接驱动显示器显示画面；

[vga_lcd](https://github.com/freecores/vga_lcd)支持多种分辨率模式、多种色深模式，其不止是一个VGA控制器，还支持鼠标显示；此外该项目还包含了VGA模块跟存储模块的交互设置，保证了VGA颜色可以源源不断地输出，但是该项目也是最复杂的。

# VGA细节设计和设计难点

![](https://s2.loli.net/2023/07/19/EAGOHLg6V2qbNTS.png)

VGA支持如下特性：

1. 其分辨率最高为640x480，颜色深度为4以节约输出带宽
2. 其分辨率最高为640x480，颜色深度为4以节约数据存储空间

## VGA Ctrl模块的输入输出信号

| Port    | Width | Rirection | Description      |
| ------- | ----- | --------- | ---------------- |
| clk_p_i | 1     | Input     | Pixel Clock      |
| reset   | 1     | Input     | Reset Singal     |
| data_i  | 12    | Input     | Color Data Input |
| hsync_o | 1     | Output    | Horizontal Sync  |
| vsync_o | 1     | Output    | Vertical Sync    |
| blank_o | 1     | Output    | Blank Sync       |
| r_o     | 4     | Output    | Red Color Data   |
| g_o     | 4     | Output    | Green Color Data |
| b_o     | 4     | Output    | Blue Color Data  |
| v_addr  | 10    | Output    | Vertical index   |
| h_addr  | 9     | Output    | Horizontal index |

信号说明：

1. clk_p_i, reset: 时钟信号，跟像素输出所需要的频率有关；复位信号
2. data_i：从内存里读取的颜色信号，一共12bit，每个颜色占4bit
3. r_o, g_o, b_o：颜色信号，每个颜色信号占 4 bit，输出的颜色信号会被数模转换模块(DAC)转化为对应的模拟信号
4. hsync_o, vsync_o：同步信号、低有效，分别是“水平同步”、“垂直同步”，各同步信号对于图像输出的作用如下图所示

   ![](https://s2.loli.net/2023/07/19/5FxhmHw4ZItsuKG.png)

5. blank_o：空白信号、低有效，该信号为高的时候，表明显示器上没有图像显示，blank信号有效时，DAC输出的模拟信号会被强制拉低
6. v_addr, h_addr：像素点的坐标，该坐标主要用于从Data Memory里面去读取对应的像素信息，每次从Data Memory里读取12 bits数据，输入到VGA中

## 内存计算相关

640x480的屏幕，一帧画面需要的存储为MEM，则

$$
MEM = 640 * 480 * 12 = 3.51 MB
$$

> 为了保证VGA能够输出连续的画面，VGA需要输出的一帧的色彩数据，需要提前写入到Memory中，然后供VGA读取

1. 针对640x480的屏幕，令其存储为RAM一共有640*480=307200行，每一行占12 bit，在数据读取的时候，
   根据`index=h_addr*480+v_addr`，再由该index作为索引取出12bits的数据
   **Question:**既然VGA输出信号是从左到右、从上到下顺序输出的，我们是否需要能够在一帧画面输出开始之后，顺序从Data Memory里取出数据给到VGA，从而不用使用地址进行索引？

2. 为了保证Core写入数据到Data Memory跟VGA 从Data Memory数据被VGA读出时互不干扰，Data Memory采用Ping Pong Memory的结构，保证一读一写； Data Memory内部需要维护读写操作

## Optional：调节输出的分辨率

<u>只需要把刷新的上界的值存储在**寄存器**里，就可以支持不同的刷新率跟分辨率了</u>，
如果只需要固定的640x480分辨率，则可以将相关参数在RTL代码里写死.

```verilog
  //640x480分辨率下的VGA参数设置
  parameter    h_frontporch = 96;
  parameter    h_active = 144;
  parameter    h_backporch = 784;
  parameter    h_total = 800;

  parameter    v_frontporch = 2;
  parameter    v_active = 35;
  parameter    v_backporch = 515;
  parameter    v_total = 525;
```

如上所示，VGA输出的信号都是有上述信号来计算产生的，例如同步信号的计算如下：

```verilog
  //生成同步信号
  assign hsync = (x_cnt > h_frontporch);
  assign vsync = (y_cnt > v_frontporch);
```

在不同的分辨率下上述参数有不同的数值，如下表所示；若上述参数不是在RTL代码里固定写死的，而是通过寄存器里读出，那么VGA模块在实际运行的时候，就可以支持输出不同的分辨率以及频率了。

![](https://s2.loli.net/2023/07/19/4kWq2lSJR7pvgao.png)

## 难点分析

1. Core的时钟跟VGA的时钟不同，需要数据时钟域的切换；此外，能否保证Ping Pong Memory跟VGA是一个时钟域？
2. 如何正确地选择VGA Data Memory的容量，才可以保证其能够容纳VGA一帧的画面、并且不会占据太多存储空间？
3. Core如何写入数据到Data Memory？是通过load/store指令还是通过DMA？
4. 如果我们采用寄存器的方式来更改VGA输出的分辨率以及频率，则我们应该如何往这些配置寄存器里写入数据？是通过处理器往VGA配置寄存器里写入吗？
