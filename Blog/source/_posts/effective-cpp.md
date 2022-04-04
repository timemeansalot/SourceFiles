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

1. Can't emit exceptions in destructor: If an error is thrown in destructor, It will probably make the process to free resources fail.
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

In the code above, if we pass by value in copy assignment function: the object created in the copy function must be copied to f2 by copy constructor, and the object inside copy assignment must be freed by calling destructor. However, if we pass by reference in copy assignment, the call of *copy constructor and destructor* can be reduced.

1. copy all members in class. If you have add new members, you have to modify your copy constructor and copy assignment operator.
2. call copy functions of parent class when writing copy functions for child class.
3. *never* call copy constructor in copy assignment operation, vise versa. Even they are very similar with each other. You can put the common parts of the two functions into a third function name *Init*, then both the copy constructor and copy assignment operator can call the Init function.



# Chapter 3. Resource Management

Resources are something you must free after finishing using them.

## Item 13: Using objects to manage resources

Because we have to delete the resource after using it. However, we can't make sure our code can reach the *delete sentence*. We have to use objects to manager resources in order to use the destructor to release the resource(C++ make sure the destructor can always be executed.) **This is called RAII(resource acquisition is initialization).**

1. auto_pointer is a pointer who will automatic call the delete function of the object which it points to. There can be only one auto_pointer pointed to the same object--> When copy one auto_pointer to another, the original copy_pointer will be destroyed--> Auto_pointers can't be stored in C++ containers, because C++ containers require the contents exhibit "normal copy behavior".
2. reference-counting smart pointers(RCSP) will count how much copy of the pointer. If there is zero copy of the RCSP pointer, it will call the delete function of the object which it points to to release resource.

## Item 14: Think carefully about copying behavior in resource-managing classes

1. Coping an RAII object entails copying the resource it manages.

## Item 15: Provide access to raw resources in resource-managing classes

1. APIs often require access to raw resources, so each RAII class should offer a way to get at the resource it manages.
2. Access may be via explicit or implicit conversion, explicit conversion is more safe while implicit conversion is more convenient for clients.

## Item 16: Use the same form in corresponding uses of new and delete

1. if use \[ \] in *new* expression, use \[ \] in *delete expression*, if don't use \[ \] in *new* expression, don't use \[ \] in *delete expression*.

## Item 17: Store new_ed objects in smart pointers in standard statements

1. Failure to do this can lead to subtle resource leaks when exceptions are thrown.



# Chapter 4. Designs and Declarations

## Item 18: make interfaces easy to use correctly and hard to use incorrectly

1. Good interfaces are easy to use correctly and hard to use incorrectlly.
2. Prevent error include consistency in interfaces and behave compatibility with build-in types.

## Item 19: Treat class design as type design

Class design is type design. Before defining a new type, be sure to consider all the issues discussed in this item.



## Item 20: Prefer pass-by-reference-to-const to pass-by-value

1. For user defined type, it's more efficient to pass-by-reference-const than pass-by-value. Because pass by reference will not create new object, so no copy constructor or destructor are used.
2. *Slicing problem:* If you pass by value and set parameter as parent class type, when you put a child child object to that function, only the parent class part can be copied while the child class part will be drop. 
3. For build-in type, STL iterator and function object type, it's more convenient to pass-by-value, they are easy to copy.
4. Pass-by-value are indeed pass **pointers**.

## Item 21: Don't try to return a reference when you must return an object

Don't pass reference to objects that not exists.

1. Any function return a pointer or reference to a local object is not allowed, because local object will be destroyed when the function exits.
2. Don't return reference of pointer to static local object, though they will not be destroyed, but there could be an issue if more than one of that object is needed.

## Item 22: Declared data members private

1. Hiding data members behind function can easily control the read and write access of data member
2. If you make clients access data members directly, your ability to change anything public is extremely restricted. Because to much clients code will broken if you make a change to your class.
3. In fact, protected data members are no more encapsulated than public data members.
