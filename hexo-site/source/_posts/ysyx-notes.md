---
title: 一生一芯记录
date: 2023-03-13 15:45:26
top: true
tags:
  - RISCV
  - YSYX
---

![ysyx home](https://s2.loli.net/2023/03/13/UyC3hr8zgHu4jLS.png)
一生一芯学习过程中的记录，参考: ["一生一芯"课程主页](https://ysyx.oscc.cc/docs/)

<!--more-->

# To Do Lists

按照 YSYX 给出的[学习规划](https://ysyx.oscc.cc/docs/schedule-origin.html)进行学习，
对于自己比较熟悉的内容选择了<u>跳过</u>或者是<u>粗略阅读相关学习讲义</u>。

- [x] 预学习阶段:
  - Start Learning: Wed Jun 28 17:09:22 CST 2023
  - Finish Learning:
- [ ] B 阶段：基础阶段
- [ ] A 阶段：进阶阶段
- [ ] S 阶段：专家阶段

# 预学习阶段笔记

预学习阶段[课程主页](https://ysyx.oscc.cc/docs/prestudy/prestudy.html)，个人认为预学习主要的内容是：

- 安装 Linux，完成[PA0](https://ysyx.oscc.cc/docs/ics-pa/PA0.html), _[PA](https://ysyx.oscc.cc/docs/ics-pa/)
  是 programming assignment 的缩写_
- TBD: 熟悉 Linux 的操作、基础命令
- TBD: 配置 Veriloator 环境，为后续处理器开发做准备
- TBD: 学习 C 语言、学习程序编译、链接、加载相关的知识
- TBD: 学习 GDB 使用，参考[ysyx: Learning to use basic tools](https://ysyx.oscc.cc/docs/ics-pa/0.5.html#learning-to-use-basic-tools)
- 学习数字电路相关的基础知识，完成[PA1](https://ysyx.oscc.cc/docs/ics-pa/PA1.html)

1. 学会提问, 安装 Linux: PASS
2. Linux 基本使用: PASS

## 搭建 verilator 仿真环境

> 个人认为“相当重要的章节”，介绍了 YSYX 的开发环境，如果按照此章节的方法去配置 Ubuntu20.04，
> 则后续安装软件的时候，很有可能会安装到跟 YSYX 不一致的版本，导致编译的时候出错

### PA0 学习记录

_Finish Time: Wed Jun 28 17:43:42 CST 2023_.

[PA0 的课程主页](https://ysyx.oscc.cc/docs/ics-pa/PA0.html)，主要的内容如下所示：

1. 配置 Ubuntu 20.04 的源，这样在安装软件的时候就能够保证安装的版本跟 YSYX 是一致的、也可以避免软件不存在的问题：

   ```bash
   sudo bash -c 'echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse" > /etc/apt/sources.list'
   sudo apt-get update && sudo apt-get upgrade -y
   ```

   > PS: 安装完 Ubuntu 20.04 之后，进入系统会提示你升级软件，**不要选择升级**，应按照上述代码操作先配置 Ubuntu.

   ![do not upgrade](https://s2.loli.net/2023/06/28/lEVp8fSn2dsxYyz.png)

2. 安装一些必要的工具，为后续的开发做准备:
   ```bash
   sudo apt-get install build-essential     # build-essential packages, include binary utilities, gcc, make, and so on
   sudo apt-get install man                 # on-line reference manual
   sudo apt-get install gcc-doc             # on-line reference manual for gcc
   sudo apt-get install gdb                 # GNU debugger
   sudo apt-get install git                 # revision control system
   sudo apt-get install libreadline-dev     # a library used later
   sudo apt-get install libsdl2-dev         # a library used later
   sudo apt-get install llvm llvm-dev       # llvm project, which contains libraries used later
   sudo apt-get install llvm-11 llvm-11-dev # only for ubuntu20.04
   ```
3. 增加开发效率的工具：vim, tmux。这些工具前期学习成本很高，但是用熟练了确实可以提升 coding 的效率，
   目前本人已经离不开 neovim 跟 tmux 了，这是我对 tmux 跟 neovim 的[配置文件](https://github.com/timemeansalot/env_config)
4. Linux 命令熟悉，重要的 Linux 命令如下所示：
   - [x] 文件管理 - cd, pwd, mkdir, rmdir, ls, cp, rm, mv, tar
   - [x] 文件检索 - cat, more, less, head, tail, file, find
   - [x] 输入输出控制 - 重定向, 管道, tee, xargs
   - [ ] 文本处理 - vim, grep, awk, sed, sort, wc, uniq, cut, tr: TBD
   - [ ] 正则表达式: TBD
   - [x] 系统监控 - jobs, ps, top, kill, free, dmesg, lsof
5. 🌟 做 PA 以及通过 Git 记录自己的提交过程，请参考[YSYX 给的提交规范](https://ysyx.oscc.cc/docs/ics-pa/0.6.html)

6. 根据[YSYX Getting Source Code for PAs](https://ysyx.oscc.cc/docs/ics-pa/0.6.html#getting-source-code)
   从 Github 上克隆 PA 的仓库，并且开始 PA0

### PA1 学习记录

PA1 的[YSYX 课程主页](https://ysyx.oscc.cc/docs/ics-pa/PA1.html)，PA1 的最终目标是为了实现 NEMU，
NEMU 是一个硬件模拟器，可以让其他程序在 NEMU 上运行。
个人认为 PA1 的主要内容如下所示：

1. 开始 PA1 之前保存 PA0 的 Git 记录:
   ```bash
   git commit --allow-empty -am "before starting pa1" # 在PA0分支下提交
   git checkout master                                # 切换到master分支
   git merge pa0                                      # merge PA0
   git checkout -b pa1                                # 创建并且切换到新分支PA1
   ```
2. 使用`make`编译程序、使用`ccache`来缓存编译的中间文件从而节省编译的时间

## 数字电路基础实验

## 复习 C 语言, 完成 PA1

# B 阶段：基础阶段笔记

# A 阶段：进阶阶段笔记

# S 阶段：专家阶段笔记

# 第六期YSYX

[项目介绍](https://ysyx.oscc.cc/project/project-intro.html#%E9%A1%B9%E7%9B%AE%E4%BA%AE%E7%82%B9)
![](https://ysyx.oscc.cc/res/images/project-intro-total-2.jpg)
学习路线：
![](https://ysyx.oscc.cc/res/images/project-intro-route.jpg)

## 阅读资料

### 预学习

1. 如何科学的提问
   - [ ] [别像弱智一样提问](https://github.com/tangx/Stop-Ask-Questions-The-Stupid-Ways/blob/master/README.md)
   - [ ] [提问的智慧](https://github.com/ryanhanwu/How-To-Ask-Questions-The-Smart-Way/blob/main/README-zh_CN.md)
2. Linux系统安装和基本使用
   - [ ] [Linux 101](https://101.ustclug.org/Ch01/)：中国科学技术大学 Linux 用户协会发起的Linux101
3. 复习C语言
   - [ ] [Linux C编程一站式学习open in new window](http://akaedu.github.io/book/)
   - [ ] [The C programming language (2nd Edition)open in new window](http://math.ecnu.edu.cn/~jypan/Teaching/ParaComp/books/The C Programming Language 2nd.pdf): 真正的C语言之父是这本书的作者[Dennis M. Ritchieopen in new window](http://en.wikipedia.org/wiki/Dennis_Ritchie), 而不是谭浩强
   - [ ] [GDB使用教程](http://akaedu.github.io/book/ch10s01.html)
   - [ ] [SEI CERT C Coding Standardopen in new window](https://wiki.sei.cmu.edu/confluence/display/c/SEI+CERT+C+Coding+Standard)
   - [ ] [Learn C the hard wayopen in new window](https://www.cntofu.com/book/25/index.html)中文版：C语言入门必做题练习0到练习18， 练习32，练习33，练习42，练习44 需要完成编程算法以及附加题.
4. 数字电路
   - [ ] [南大数字实验](https://nju-projectn.github.io/dlco-lecture-note/index.html)
         以下部分是必做题：
     - 实验一 选择器
     - 实验二 译码器和编码器
     - 实验三 加法器与ALU
     - 实验六 移位寄存器及桶形移位器
     - 实验七 状态机及键盘输入
   - [ ] [Chisel API](https://javadoc.io/doc/org.chipsalliance/chisel_2.13/latest/index.html)

## PA 阅读资料

### PA0

- [ ] [Linux入门教程 by jyy](https://ysyx.oscc.cc/docs/ics-pa/linux.html)
- [ ] [鸟哥的Linux私房菜](https://linux.vbird.org/linux_basic/)
- [ ] [man快速入门](https://ysyx.oscc.cc/docs/ics-pa/man.html)
- [ ] [GDB guide](https://www.cprogramming.com/gdb.html)
- [ ] [The Missing Semester of Your CS Education](https://missing.csail.mit.edu/)
