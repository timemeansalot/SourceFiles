---
title: 数字通信笔记
date: 2023-04-18 19:27:50
tags: DigitalCommunication
---

数字通信笔记

<!--more-->

## 相关知识点

<div style="text-align:center"><img src="/Users/fujie/Pictures/typora/image-20230418194100696.png" alt="image-20230418194100696" style="zoom:50%;"/></div>

1. 信源编码(source encoder)
   - 任务：将输入(input)变成二进制序列(binary sequence)，用于后续数字处理
     1. 输入可能是直接的符号，例如英语字母，此时可以通过 5bits 对英语字母进行 **encoding**；
     2. 输入也可能是连续的信号，例如传感器的输入，此时需要: 采样(**sampling**)->量化(**quantization**)->编码(encoding)，例如语音信号的输入，需要 8000hz 的采样率进行信号采样->再量化为 256 个水平->在用 8bits 进行编码
     3. 符号(symbol)：量化后会得到一个数值，该数值是一个“量化符号”，对该量化符号进行编码之后，会得到一个“二进制符号(binary symbol)”  
        例如采用 5bits 对英文字母编码，则 00000 表示字母 a，那么 00000 就是一个二进制符号
        <div style="text-align:center"><img src="/Users/fujie/Pictures/typora/image-20230418202516910.png" alt="image-20230418202516910" style="zoom:33%;" /></div>
   - 目标：编码之后，数字信号尽可能少，这就涉及到了压缩(**compression**)的概念
   
2. 信道(channel):
   - 对于编码设计者来说，信道是不可控的因素。信道可以是数字信道(输入输出都是二进制序列)、空气、双绞线等
   - 信道可以由其<u>输入到输出的关系来描述</u>, 例如当信道是*线性时不变(linear time-invariant)*系统的时候，信道可以由其脉冲响应或者频率响应来描述
   - 信道一般不会是理想的 LTI 系统，会有噪音(noise)  
     $Y(t)=X(t)+N(t), Y(t)$是信道的输出，$X(t)$是信道的输入、$N(t)$是信道的噪音、通常会被建模成高斯随机过程
   
3. 信道编码(channel encoding)：将代发送的数据编码成可以在信道上传输的数据
   - 带发送数据是模拟信号时：将模拟信号调制(**modulation**)到 sin 信号上(analog -> waveforms)
   - 带发送数据是数字信号时：将数字信号先转化成模拟信号, 再将模拟信号调制(modulation)到 sin 信号上(binary -> analog -> waveforms)
     1. 数字信号转化为模拟信号(波形)的过程：首选选取一个基础波形 p(t)、调制数字信号$u_n$序列，$Wave=\sum{u_np(t-n/R)}$
     2. 常见的调制方法有：2-PAM(binary pulse amplitude modulation), QAM(quadrature amplitude modulation)
   - 错误检测(error detection)：为了能够检测到传输过程中的错误信号，可以在调制前面对需要调制的信号进行**纠错编码 error encoding**，然后发送带有纠错码的信号；在接收端解调制(demodulation)之后，再通过 error decoding 判断错误情况
   - 通带信号(passband)：经过调制之后得到的waveform是基带的waveform-> $u(t)$，还需要被映射到通带的waveforms->$x(t)$才可以发送. 通带的waveform以频率$f_c$对称  
   $x(t)=R\{u(t)e^{2\pi if_ct}\}$
   
   <img src="/Users/fujie/Pictures/typora/image-20230418220950760.png" alt="image-20230418220950760" style="zoom:33%;" />
   
4. 二进制接口(binary interface)：数字接口可以进一步根据网络划分成多个等级，跟计算机网络里的分级对应
   <div style="text-align:center"><img src="/Users/fujie/Pictures/typora/image-20230418201931571.png" alt="image-20230418201931571" style="zoom: 33%;" /></div>
