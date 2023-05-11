---
title: Verilog语法学习笔记
date: 2022-09-07 10:22:01
tags:
  - Verilog
---

此文档包含我学习 Verilog 时遇到的问题，对于一些第一次遇到的 Verilog 关键字进行了记录

# Verilog 基础

[Verilog 代码规范](https://www.runoob.com/w3cnote/verilog2-codeguide.html), [Verilog 编码风格](https://www.runoob.com/w3cnote/verilog2-codestyle.html)

1. verilog 定义模块的时候，其输入端口只能定义成`wire`(从模块内部来看，外部输入给它的信号就是一个导线)，其输出端口可以定义成`wire`，也可以定义成`reg`
2. verilog 例化模块的时候，模块的输入端口可以链接到`wire`或者`reg`，模块的输出只能连接到`wire`(从模块外部来看，模块输送到外部的信号也只是一个导线)
3. 组合逻辑电路：

   - 简单的组合逻辑电路可以用`assign`语句来实现，例如:

     ```verilog
     module mux (
         input            sel ,
         input  [3:0]     p0 ,
         input  [3:0]     p1 ,
         output reg [3:0]    sout
       );

        assign sout = (sel==1'b0) ? p0:p1;
     endmodule
     ```

   - 复杂的组合逻辑电路可以用`always@(*)`来实现，由于实用了 always 语句，输出数据必须被声明为`reg`类型。但是不用担心它的结果会被锁存一拍，实际上其生成的电路跟`assign`语句生成的电路是一样的，例如下面的代码跟上面的代码，其生成的电路是一样的：

     ```verilog
       module mux (
         input            sel ,
         input  [3:0]     p0 ,
         input  [3:0]     p1 ,
         output reg [3:0]    sout
       );

        //assign sout = (sel==1'b0) ? p0:p1;

        always @(*) begin
          if(sel==0) begin
            sout = p0;
          end
          else begin
            sout = p1;
          end
        end

       endmodule
     ```

4. 测试文件，一个简单的测试文件包括如下的重要部分：

   - 信号声明（测试用例里面的信号，输入信号声明为`reg`，输出信号声明为`wire`
     - 基础信号：时钟、复位
     - 测试用例(dut)涉及到的相关信号
   - 输入信号赋值:
     - 生成周期时钟
     - 生成 dut 输入信号
   - 例化 dut
   - 生成波形
   - 进阶部分（文件操作&生成内部数组的波形）

   ```verilog
   module mux_tb ();

      reg clk,resetn; // 基本的信号：时钟、复位信号

      // 测试模块(dut)涉及到的信号
      reg sel;
      reg [3:0] p0, p1;
      wire [3:0] sout;

      // 控制测试周期&生成波形需要用到的信号
      integer i, counter;

      // 生成周期时钟
      initial begin
        clk<=0;
        counter <= 0;
        forever begin
          #1; clk<=~clk;
        end
      end

      // 设置每个周期的输入测试信号
      always@(posedge clk) begin
        if(counter==0)begin
          resetn <= 0;
          p0     <= 4'b110;
          p1     <= 4'b111;
          sel    <= 0;
        end

        if(counter==1)begin
          resetn <= 1;
        end

        if(counter==2)begin
          sel <= 1'b0;
        end

        if(counter==10)begin
          $finish();
        end

        counter+=1;
      end

      // 生成波形文件
      initial begin
        $dumpfile("mux_tb.vcd");
        $dumpvars(0, mux_tb);
      end
      // 例化测试对象
      mux muxInstance(
      .sel(sel),
      .p0(p0),
      .p1(p1),
      .sout(sout)
      );
      // 进阶1：从文件读取输入数据&输出结果到文件
      // 进阶2：打印波形的时候，打印内部的数组（默认情况下是不会打印dut内部数据数据的
    endmodule
   ```

5. 文件操作：可以直接从文件读取数据来给“dut 输入信号赋值”，也可以直接通过文件读取数据“来给 dut 内部数组赋值”,
   [参考：runoob.com Verilog 文件操作](https://www.runoob.com/w3cnote/verilog2-file.html)

   - 给 dut 输入信号赋值
     ```verilog
         integer fd, err;
         integer code;
         reg [640:0] str; // 打开文件错误时，返回值
         reg [31:0] src; // 寄存器
         //string str,str2;
         initial begin
           fd = $fopen("compressDecoderInput.txt", "r"); // 打开一个文件
           err = $ferror(fd, str); // 判断该文件是否存在
           if(!err)begin // 如果文件打开成功
            // code = $fread(src, fd);
            code =$fscanf(fd, "%d", src); // 从文件里读取数据到寄存器里
            $display("src is %d", src);
           end
           $fclose(fd); // 关闭文件
         end
     ```
   - 给 dut 内部数组赋值
     ```verilog
         initial begin
           //格式: readmemh(file, target, start, length)
           $readmemh("i-memory.txt", muxInstance.sramInstance.m_array,0,15);
         end
     ```

6. 输出 dut 内部数组的波形（verilog 默认情况下只会输出 dut 内部信号的波形，但是不会输出 dut 内部的数组的波形），因此需要手动通过一个循环，逐行输出 dut 的内部数组

   ```verilog
     initial begin
       $dumpfile("mux_tb.vcd");
       $dumpvars(0, mux_tb);
       for(i=0;i<16;i++) // 循环输出内部数组每一行的波形
         $dumpvars(0, muxInstance.sramInstance.m_array[i]);
     end
   ```

7. Makefile：使用 Makefile 是为了更方便地编译文件、运行仿真、生成波形

   ```Makefile
   # Makefile
   src = compressDecoder
   include iverilog.mk
   ```

   ```Makefile
    # iverilog.mk
   .PHONY: clean all run waveform

   DEFAULT_GOAL:=all
   all: ${src}.v ${src}_tb.v
       @iverilog -o ${src}_tb.vvp ${src}_tb.v # @ means don't echo this command to terminal, just run it.

   run: all
       vvp ${src}_tb.vvp

   waveform: run
       @gtkwave ${src}_tb.vcd -a gtkwave_setup.gtkw

   clean:
       -rm *vcd *vvp
   ```

8. 打印控制信息: `$write`打印完后自动不换行、`$display`：打印完后要自动换行
9. 逻辑符号：
   - `&&`：逻辑与、`&`：按位与
   - `!`: 逻辑取反、`~`：按位取反

# FIFO
