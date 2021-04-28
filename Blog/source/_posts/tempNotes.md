---
title: tempNotes
date: 2021-04-25 16:11:18
tags: TempNotese
---





My temp notes.

<!--more-->

[[_TOC_]]

# Link

在C++中，每个.cpp文件可以被当做一个单独的编译单元，会生成对应的.obj文件；每个对应的.obj文件，会有两个表：

- 导出符号表：该.cpp文件中的非static变量和函数定义
- 未解决符号表：该.cpp文件中，未给出定义的变量和函数；需要由别的文件给出其定义





```c++
// @file Log.h
#include <stdio.h>
int log(const char *message)
{
    printf("Message is %s",message);
}

static int log1(const char *message)
{
    printf("Message is %s",message);
}

inline int log2(const char *message)
{
    printf("Message is %s",message);
}

class People
{
public:
  int age;
  void showAge()
  {
      printf("age is %d\n",age);
  }
};
// @file Multiple.cpp
#include "Log.h"
int multipul(int a,int b)
{
    return a*b;
}

// @file main.cpp
#include "Log.h"
int main()
{
	printf("1*2=%d",multipul(1,2));    
}
```

1. log会被复制到multiple和main中，所有会报multiple definition 错误（multiple对应的obj文件和main对应的obj文件的导出符号表都会有关于Log的定义，所以会报multiple definition错误）
2. log1，log2和People都只在Log.h中可见，虽然预处理将其复制到了main和multiple文件中去，但是他们不会被添加到对应的obj文件的导出符号表中。（只有在多个导出符号表中的函数，才会报multiple definition错误）
3. PS：一般将函数的声明放到头文件里，将函数的定义放到源文件里；一般将类的声明和定义都放到头文件里。



# Const

const是由编译器提供支持的，编译器在编译的时候，会禁止对const变量的修改。



## const & pointer

```c++
char *p; // non-const pointer, non-const data
const char *p; // non-const pointer, const data 
char const *p; //equat to above
char * const p; // const pointer, non const data
const char* const p; // const pointer, const data
```



## const & return

通过const修饰返回值，可以避免对返回值的错误操作，如

```c++
const int sum(int a, int b)
{
    return a+b;
}

int a=10, b=20, c=30;
if(sum(a,b)=c)
{
    printf("a+b==c");
}
else 
{
    printf("a+b!=c");
}
```

加入我们想判断的a+b是否等于c，但是在判断的时候，错把==写成了=。

- 如果使用const修改返回值int，则编译器会检查出这个错误（因为返回值用const修饰了，不可以被更改）
- 如果不使用const修改返回值int，则编译器不会检查出这个错误。



## const&成员函数

const修饰成员函数，表示该函数不可以修改类的任何成员变量。

```c++
class Test
{
  private:
    int a;
    mutable int b;
   public:
   	int & getA() const
    {
        a=10; // 不合法
        b=20;
        return a;
    }
};
int main()
{
    Test test;
    test.getA()=10;
}
```

getA函数由const修饰，所以是一个const成员函数，它不可以修改类的成员，故：

- a=10不合法
- b=20合法，因为被**mutable修饰的成员变量**即使在const函数内，也可以被修改。
- 但是test.getA()合法：getA函数返回了一个a的引用，通过此引用修改a的值



non-const成员函数可以调用const成员函数，但是const成员函数却不能调用non-const成员函数（因为const成员函数一定不能修改成员变量，但是non-const成员函数却不一定修改了成员变量，如果const成员函数调用的non-const成员函数修改了成员变量，则违反了const成员函数的规定）。

```c++
class TextBlock
{
  	private:
      char *Text;
    public:
    
      // const 版本
      const char& operator [ ] (int position) const
      {
          return Text[position];
      }
     // non-const 版本调用const版本
    char & operator [ ] (int position)
    {
        return 
            const_cast<char &>(static_cast<const TextBlock &>(*this)[position]);
    }
};
```

non-const成员函数在调用const成员函数实现相似的逻辑的时候，发生了两次类型转换：

- 将this转换为const类型以调用cosnt成员函数
- 将返回值从const char &转换为char &





# 构造、析构、赋值

C++会为每个类自动生成：构造函数、析构函数、copy函数和赋值函数（如果需要且未被定义）。如果想要禁止这4个函数，可以手动将其声明为private但是不写定义。

## 虚析构函数

当父类的析构函数不是虚析构函数的时候，企图用父指针指向子类对象调用子类的析构函数，将只能调用父类的析构函数，会导致**部分析构错误**。

虚函数的实现是通过**虚函数表和虚函数指针**实现的。

一般只有当前的类会作为别的父类（当前类有virtual修饰的函数）时，才将其的虚构函数用virtual修饰，否则只会增加负担。即**一般会将父类的虚构函数用virtual修饰，这样才可以正确释放子类对象的资源**



## 纯虚析构函数

```c++
class Test
{
  public:
    virtual ~Test(){}=0; // 纯虚构函数
};
```

- Test有纯虚函数，不可以实例化
- 补充了虚函数的定义为{ }，必须这么做，因为析构的顺序是从子类开始，调用父类的虚构函数。如果父类虚构函数没有定义，则会报错。



# 智慧指针&引用计数型智慧指针

这两者都是关于资源的管理类。

- 智慧指针：std::auto_ptr<>
- 引用计数型智慧指针：std::tr1::shared_ptr<>

使用对象的形式来管理资源，其析构函数一定会在结束时释放资源。

资源取得时机便是初始化时机ARII(Resource Acquisition is initialization)，可以避免错过对于资源的delete操作，造成资源泄露。







