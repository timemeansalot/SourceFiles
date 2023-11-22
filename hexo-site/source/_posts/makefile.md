---
title: makefile
date: 2023-11-22 10:14:17
tags: Notes
---

Makefile笔记

[TOC]

<!--more-->

# foreach

1. 格式
   ```makefile
   $(foreach n, source, operation(n))
   ```
   source里的变量用n表示，采用`operation`对n进行操作，返回操作后的结果
2. 例子
   ```makefile
   foo=a b c
   target=$(foreach n, $(foo), $(i).cpp)
   ```
   得到的`target= a.cpp b.cpp c.cpp`

# wrod, i

1. 格式

   ```makefile
   $(word i, source)
   ```

   返回source里的第i个变量

2. 例子
   ```makefile
   foo=a b c
   target=$(word 2, $(foo))
   ```
   得到的`target=b`

# filter

1. 格式

   ```makefile
   $$(filter method, source)
   ```

   使用method方法对source进行筛选，返回符合source里符合method筛选后的结果

2. 例子
   ```makefile
   foo=a.cpp b.h c.c
   target=$$(filter %.cpp, $(foo))
   ```
   得到的`target=a.cpp`

# ifeq

1. 格式

   ```makefile
   ifeq(a,b)
       function
   endif
   ```

   如果ifeq的条件满足，就执行function

2. 例子
   ```makefile
   foo=a b c
   ifeq($(foo),)
     xx
   endif
   ```
   不会执行xx的内容，因为foo不等于<u>_空_</u>

# call

1. 格式

   ```makefile
   $(call function, param1, param2,... )
   ```

   调用函数function，并且为该函数传入参数param1, etc

2. 例子

   ```makefile
    reverse =  $(2) $(1)
    target = $(call reverse,a,b)
   ```

   得到的`target=b a`

# template

1. 格式

   ```makefile
   $(word i, source)
   ```

   返回source里的第i个变量

2. 例子
   ```makefile
   foo=a b c
   target=$(word 2, $(foo))
   ```
   得到的`target=b`
