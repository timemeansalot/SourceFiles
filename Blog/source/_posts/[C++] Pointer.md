---
title: C++指针笔记
date: 2021-04-28 17:21:02
tags: 
- C++
- Pointer
---



C++指针学习笔记，所有关于C++指针的笔记在此。

<!--more-->



[[_TOC_]]

# 指针究竟是什么

> 指针是表示地址的数字

数据存储在内存中，64位的计算机，其内存地址从0~2^64递增，根据内存地址，就可以直接读取出内存里的数据。

而指针的值就是内存地址，所以我们可以直接通过指针，取出对应内存里的数据。

```c++
/**
 * @file main.cpp
 * @brief Main file for learning C++
 * @author jfu
*/
#include <iostream>
#include <string.h>
using namespace std;

int main()
{
    int a = 10, b = 20;
    int *aa = &a, *bb = &b;
    cout << "aa= " << aa << endl
         << "bb= " << bb << endl;
    cout << "bb-aa= " << bb - aa << endl;

    return 0;
}
```

控制台输出的结果如下：

```markdown
aa= 0x7ffdb21d03f0
bb= 0x7ffdb21d03f4
bb-aa= 1
```

我们可以看出int型元素a存储在内存中`0x7ffdb21d03f0`的位置，int型元素b存储在内存中`0x7ffdb21d03f4`的位置，二者的位置刚好相差了4B。可见，指针存储的就是对应元素在内存中的位置。

而bb-aa=1，这是因为，两个指针相减，返回的是两个元素之间的偏移（元素的个数）。

# 指针的类型

```c++
int a=10;
double b=20;
int *p=&a;
double *q=&b;
```

在C++里，我们可以声明不同类型的指针。但是上面我们说到了，指针的本质其实就是一个数字，指向内存地址，以64位计算机为例，所有指针都是宽度为8B的二进制数。

指针本质上都是数字，不同类型的指针没有区别。之所以指定指针为int类型，只是为了标记一下，该指针指向的内存中，存储的是int类型的数据而已，方便我们使用指针。



# 指针与const

```c++
const int *a; 
int const *b;
int const *c;
const int const *d;
```

- a和b都是指向`int *`类型数据的指针，它指向的数据，其值不可更改，但是可以改变a所指向的数据。

  ```c++
  *a=10; // 不合法，不可以改变指针a所指向的数据的值
  const int aa=0;
  a=&aa; // 合法，可以改变指针a所指向的数据
  ```

- c是指向`int`型数据的指针，它指向的数据的值可以改变，但是它不可以指向别的数据

  ```c++
  *c=10; // 合法，可以改变c所指向的数据的值
  int cc=10;
  c=&cc;// 不合法，不可以将c指向别的数据
  ```

- d是以上二者数据的结合。它指向的数据的值不可改变，同时d也不可指向别的数据

  ```c++
  *d=10; // 不合法，不可以改变d所指向的数据的值
  const int dd=10;
  d=&dd; // 不合法，不可以将d指向别的数据
  ```



# 浅复制&深复制

### 浅复制

- 类的成员中有指针
- 没有在类的拷贝构造函数中，说明copy时要为该指针申请内存
- 那么该类的对象的复制操作，将会导致两个类共用同一个指针

```c++
/**
 * @file mPointer.h
 * @brief Test pointer shallow copy in C++
 * @author jfu
*/
#include <iostream>
#include <string.h>
using namespace std;

/**
 * @brief class Person without copy constructor
 * @version v1.0
*/
class Person
{
private:
    char *m_name;
    int m_age;

public:
    Person(char *name, int age)
    {
        m_name = new char[20];
        strcpy(m_name, name);
        m_age = age;
    }
    void setName(char *name)
    {
        strcpy(m_name, name);
    }
    void showInfo()
    {
        cout << "My name is: " << m_name << " and my age is " << m_age << endl;
    }
};

int TestPointer();

/**
 * @file mPointer.cpp
 * @brief Test class Person in file mPointer.h
 * @author jfu
*/
#include "mPointer.h"

/**
 * @brief Test shallow copy
*/
int TestPointer()
{
    Person p("Tom", 20);
    p.showInfo();

    Person q = p;
    q.showInfo();
    q.setName("Jack");

    p.showInfo();
    q.showInfo();
    return 0;
}

/**
 * @file main.cpp
 * @brief Main file for learning C++. This file using functions, variables in other files.
 * @author jfu
*/
#include "mPointer.h"

int main()
{
    TestPointer();
    return 0;
}
```

使用命令`g++ -o main main.cpp mPointer.cpp`编译文件，输出结果如下：

```markdown
My name is: Tom and my age is 20
My name is: Tom and my age is 20
My name is: Jack and my age is 20
My name is: Jack and my age is 20
```

可见，Person对象p和q中的m_name指针，是同一个指针，这就是所谓的浅复制。



### 深复制

- 类的成员中有指针
- 在类的拷贝构造函数中，说明copy时要为该指针申请内存
- 那么该类的对象的复制操作，两个类会各自拥有各自的指针

```c++
/**
 * @file mPointer.h
 * @brief Test pointer shallow copy in C++
 * @author jfu
*/
#include <iostream>
#include <string.h>
using namespace std;

/**
 * @brief class Person without copy constructor
 * @version v2.0
*/
class Person
{
private:
    char *m_name;
    int m_age;

public:
    Person(char *name, int age)
    {
        m_name = new char[20];
        strcpy(m_name, name);
        m_age = age;
    }
    // add copy constructor to enable deep copy
    Person(Person &person)
    {
        m_name=new char[20];
        strcpy(m_name,person.m_name);
        m_age=person.m_age;
    }
    void setName(char *name)
    {
        strcpy(m_name, name);
    }
    void showInfo()
    {
        cout << "My name is: " << m_name << " and my age is " << m_age << endl;
    }
};
int TestPointer();
```

输出结果如下：

```mark
My name is: Tom and my age is 20
My name is: Tom and my age is 20
My name is: Jack and my age is 20
My name is: Jack and my age is 20
```

可见，在添加了拷贝构造函数之后，对于Person对象p和q中的m_name指针，分别是不同的指针。