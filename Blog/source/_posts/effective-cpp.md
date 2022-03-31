---
title: effective_cpp
date: 2022-03-28 14:26:03
tags: Programming
---



学习《Effective C++》的读书笔记



<!--more-->



## Item 4: always initialize object before using it

1. manually initialize all built-in type
2. use **initialization list** to initialize data members in class when writing constructors for class.
3. use a function which returns the reference of (this can make the **non-local static variable** become local static variable), instead of directly use non-local static variable itself. So the initialization of the local static variable will happen when the corresponding function is called. However the <u>initialization order of two non-local static variable declared in two translation unit is unknow,</u> which could be disastrous.



# Chapter 2. Constructors, Destructors and Assignment Operations





## Item 5: Know what functions C++ silently writes and calls

> If we don't create, C++ compiler will declares **constructor, copy constructor, destructor and copy assignment operator** for us. If we would use these functions in our code, the compiler will write these functions for us.



## Item 6: Explicitly disallow the use of compiler generated functions

Just as mentions in Item5, the compiler would automatically create functions for us, what can we do if **we don't want the compiler to create** some of such classes? 

For example, we want to make the copy of two objects illegal, but the compiler will always make a copy constructor and copy assignment operator for our class.

- The way to make copy of objects illegal is that **we can manually define copy constructor and copy assignment operation, but we defined them as private.** So the copy function cannot be called
- Moreover, if you **don't provide function definition** for your manually defined copy function, then you can't even call them using class member function, you will get a link error.
- You can create a base class who declared the copy function as private and doesn't provide function body. Then every **class inherits from this base class is not allow to copy.**



## Item 7: Declare destructors virtual in polymorphic base classes

If you want to use pointer of parent class to access child objects, you must declare the parent destructor as virtual. If you don't do that, when you try to free the child object using the parent pointer, you can only delete the members inherited from parent class, you can't delete the members of the child class.

- If you want to delete all members in child object using parent pointer, you must declare parent's destructor as virtual.
- It's bad to inherit from a parent class who doesn't provide virtual destructor.
- You can make an **abstract class** by declare it's destructor as a **pure virtual destructor**. But you have to provide the definition of that destructor outside the class.

## Item 8: Prevent exceptions from leaving destructors

1. Can't emit exceptions in destructor: If an error is thrown in destructor, It will probably make the process of free resources fail
2. Make a client class to deal with the exceptions, you can make a **non-destruct function** to handle with exceptions and you can handle exceptions in the destructor of client class.

## Item 9: Never call virtual functions during construction or destruction

1. Don't call virtual function in a constructor or destructor. Because if you make a constructor of parent class call a virtual function, and you think it's going to call the function of derived class. However, it can only call the virtual function in parent class itself. Because when we call the constructor of parent class, the derived class has not been defined yet, how could we call the function defined in derived class?
2. We can pass back information to parent class from child class for different derived class, so they can have different behavior.
3. **Static** functions can only modify static members of the class; it's shared by all objects of that class; it's called by class_name::function_name

## Item 10: Have assignment operation return a reference to *this

The assign operation in C++ to the right first, for example a=b=c=15, C++ first make c=15, them assign b=c, then assign a=b.

When we do operator override, the assignment operation must return \*this.

## Item 11: Handle assignment to self in operator=

When we write operator= for a class, we have to make sure the function forms well when we do **a=a**, which a is an instance of the class. There are 3 ways to assignment error and exception error:

1. compare resource address and target address
2. allocate new resource before delete old resource
3. use *copy and swap* technical

## Item 12: Copy all parts of an object

> Return reference in copy assignment operation can reduce of "copy constructor and destructor". Because if we return value in copy assignment operation, we have use copy constructor to copy the object in copy assignment function to the left value of =. For example

```c++
// define class food
food f1;
food f2=f1;
```

In the code above, if we pass by value in copy assignment function: the object created in the copy function must be copied to f2 by copy constructor, and the delete of the object inside copy assignment must be freed by calling destructor. However, if we pass by reference in copy assignment, the call of *copy constructor and destructor* can be reduced.
