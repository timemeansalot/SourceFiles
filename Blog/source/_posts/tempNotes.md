---
title: tempNotes
date: 2021-04-25 16:11:18
tags: TempNotese
---





My temp notes.

<!--more-->

[[_TOC_]]





# C++是语言联邦

C++综合了：C语言、面向对象语言、模板、STL的特点

- C语言：区块、数组、指针等
- 面向对象：封装、继承、多态、虚函数（动态绑定）
- Template：泛型编程
- STL：是一个template程序库，有：容器、迭代器、算法、函数对象

> 在使用C++时，要充分考虑C++的这四个特性，来改变编程策略。



# 使用编译器代替预处理器

```c++
#define Pie 3.14      // 使用预处理器
const double pie=3.14 // 使用编译器
```

使用编译器的好处如下：

1. 使用编译器时，变量会被写入符号表(symbol table)，这样在debug的时候，可以方便定位到对应的变量
2. 使用编译器，可以更好地节约空间，不像预处理器（只是将变量复制多份）
3. #define不具有封装的功能，一旦生效，则在文件内随处可见。



使用`inline`函数代替`#define`，可以大大减少编程时的负担及出错的概率。





# 尽量使用const

> const通过编译器，实现了一种语义约束：某值不可改变。



**const与指针：**如果const出现在星号左边，则代表数据是const的；如果const出现在星号右边，则代表指针是const的

```c++
    const char *p2 = "hello";       // non-const pointer, const data
    char const *p3 = "hello";       // non-const pointer, const data
    char *const p4 = "hello";       // const pointer, non-const data
    const char *const p5 = "hello"; // const pointer, const data
```



