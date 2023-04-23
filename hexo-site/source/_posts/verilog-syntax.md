---
title: Verilog语法学习笔记
date: 2022-09-07 10:22:01
tags:
  - Verilog
---

此文档包含我学习 Verilog 时遇到的问题，对于一些第一次遇到的 Verilog 关键字进行了记录

# 输入输出端口

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
