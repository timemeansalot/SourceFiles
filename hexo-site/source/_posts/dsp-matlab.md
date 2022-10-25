---
title: DSP用Matlab学习的笔记
date: 2022-10-25 10:24:45
tags:
    - DSP
    - Matlab
---

# Matlab 笔记
## Matlab中的常用信号
1. **sin, cos, sinc, exp**
2. **heaviside(unit step function), diract(delta function)**
3. dsolve(eqn, conditions): 解微分方程, simpify(func)：化简函数表达式func
4. lsim(sys, f,t), tf(b,a)

   lsim: t is the time axis. f is the input signal. sys is the model of the LTI system  

   For the differential equation:

   $$a_3y'''(t)+a_2y''(t)+a_1y'(t)+a_0=b_3f'''(5)+b_2f''(t)+b_1f'(t)+b_0f(t)$$
   the value of a and b is:
   $$
   \begin{matrix}a=[a_3,a_2,a_1,a_0]\\b=[b_3,b_2,b_1,b_0]\end{matrix}
   $$
   $$  
5. impluse(sys, t)  , step(sys, t) ：脉冲响应， 阶跃响应
6. tripuls(t, width, center): 三角波
7. sawtooth(t, center): 锯齿波
8. rectangle(t, center)：单个矩形波
9. square(t, range)：连续的方波，range表示高电平占周期的比例
## 微分&积分
1. 微分diff
    - symbolic: 
        ```Matlab
        syms x
        y1 = heaviside(x);
        y2 = diff(y1,x);
        ```
    - numerical, 记得除以dt
        ```Matlab
        t = -5:dt:5;
        f1 = heaviside(t);
        f2 = diff(f1)/dt; % diff 用于计算离散序列的差分，默认元素间的间隔为 1
        ```
2. 不定积分int, cumtrapz。定积分int加上区间、trapz
    - symbolic
        ```Matlab
        syms x
        c = 0;
        y1 = heaviside(x);
        y2 = int(y1,x)+c;
        % 定积分
        syms t1
        int(heaviside(t1),-1,2)
        ```
    - numerical
        ```Matlab
        dt = 0.01;
        t = -5:dt:5;
        f1 = heaviside(t);
        f2 = cumtrapz(t, f1)+c;
        % 定积分
        t2 = -1:0.01:2;
        trapz(t2,heaviside(t2))
        ```

# Chapter 2: 时序的信号分析

$$
y(t)=y_{zi}(t)+y_{zs}(t)
$$

其中$y_{zi}(t)$是零输入响应，输入为0；$y_{zs}(t)$是零状态响应，初始条件为0

## 零输入响应

𝑦𝑦′′(𝑡𝑡) + 4𝑦𝑦(𝑡𝑡) = 0, 𝑦𝑦(0-) = 1, 𝑦𝑦′(0-) = 1, find the zero_input response  

```matlab
clear;
close all;
clf;
syms y(t)
D2y = diff(y,t,2);
Dy = diff(y,t);
eqn = D2y+4*y==0; % zero input response 右边的输入是0
conds = [y(0)==1, Dy(0)==1];
ysol = dsolve(eqn,conds);
yzi = simplify(ysol);	
```

## 零状态响应

### dsolve求零状态响应

```matlab
clear;
close all;
clf;

syms y(t)
D2y=diff(y,t,2);
Dy=diff(y,t);
eqn=D2y-5*Dy+6*y==exp(-2*t)*heaviside(t); % 零状态响应右边输入不是零
conds=[y(0)==0, Dy(0)==0];                % 零状态响应的状态是0
ysol=dsolve(eqn,conds);
yzs=simplify(ysol)
```

### lsim和tf求零状态响应

```matlab
clear;
close all;
clf;

sys = tf([1],[1,-5,6]);
t = 0:0.01:5;
f = exp(-2*t).*heaviside(t);
y = lsim(sys,f,t);
plot(t,y);
xlabel('t');ylabel('y(t)');title('Zero-State Response'),grid on;
```

### 使用卷积求零状态响应

> step response和impulse response可以反映系统的特性，

