---
title: STL Notes
date: 2022-04-04 14:50:23
tags:
  - Programming
  - STL
---



> Notes about learning C++  STL

![image-20220404145224507](E:/Pictures/TyporaPictures/image-20220404145224507.png)

<!--more-->

# Containers

1. Sequence Containers: implement data structures which can be accessed in a sequential manner:
   - vector
   - list
   - deque
   - arrays
   - forward list(introduced in C++ 11)
2. Container Adaptors : provide a different interface for sequential containers.
   - queue
   - priority queue
   - stack
3. Associative Containers : implement sorted data structures that can be quickly searched (O(log n) complexity.
   - set
   - multiset
   - map
   - multimap
4. Unordered Associative Containers : implement unordered data structures that can be quickly searched
   - unordered set
   - unordered multiset
   - unordered map
   - unordered multimap

## Vectors

> Vectors are like dynamic arrays with the ability to resize automatically .

[Demo code link](https://github.com/timemeansalot/algorithm/blob/master/STL/stl_vector.cpp)

1. traverse:
   - begin()
   - end()
   - rbegin()
   - rend()
2. capacity
   - size()
   - resize(int n)
   - capacity()
   - max_size()
   - empty()
   - shrink_to_fit(): make capacity=size
3. access element
   - operator override \[ \]
   - at(int index)
   - front()
   - back()
   - data(): return a pointer pointing to the first item in vector
4. Modify elements
   - push_back(value)
   - pop_back()
   - insert(iterator,value)
   - erase(iterator,value)
   - emplacy(iterator,value)
   - emplacy_back(value)
   - clear()
   - swap(another_vector)
   - assign(size,value)

## List

> Lists are sequency containers that allow *non-contiguous* memory allocation. When talking about List, we mean doubly linked list while *forward list* refers to singly linked list.

[Demo code link](https://github.com/timemeansalot/algorithm/blob/master/STL/stl_list.cpp)

Compared to Vector, List:

- Has slow traversal
- Fast insert once index is chosen



1. access data
   - push_back(value)
   - push_front(value)
   - front()
   - back()
   - pop_front()
   - pop_back()
2. size
   - size()
   - resize(new_size)
   - empty
3. modify list()
   - assign(size,value)
   - insert(iterator, value)
   - emplace(iterator,value)
   - emplace_front(value)
   - emplace_back(value)
   - merge

