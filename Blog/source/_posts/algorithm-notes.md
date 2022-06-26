---
title: 算法笔记-学习Labuladong的算法时，做的笔记
date: 2022-04-21 10:39:42
tags: Algorithm
---

<!--more-->
# 1 数据结构基础

## 1.1 数组/链表

### 1.1.1 前缀和

> 前缀和主要应用与需要频繁地计算数组某个区间和的情况（数组本身是固定不变的）

**算法核心思想：**

1. 构造前缀和数组pre_sum: 

   - ```c++
     pre_sum[0]=0;
     for (int i=0;i<nums.size();i++)
     {
         pre_sum[i+1]=pre_sum[i]+nums[i];
     }
     ```

   - `pre_sum`数组的长度比`nums`数组+1

2. 通过O(n)的时间，可以计算出前缀和数组；然后可以通过O(1)的时间计算出任意区间的和：

   ```c++
   res=pre_sum[right+1]-pre_sum[left];
   ```



**例题：**

- [303：求一维数组区间和](https://leetcode-cn.com/problems/range-sum-query-immutable/)
- [304：求二维数组区间和](https://leetcode-cn.com/problems/range-sum-query-2d-immutable/)
- [560：和为K的子数组](https://leetcode-cn.com/problems/subarray-sum-equals-k/)（需要用到unordered_map使复杂度从$O(n^2)$降低到O(n)）

### 1.1.2 差分数组

> 差分数组用于处理需要频繁地对数组区间进行加减的操作，如频繁将数组`a[i,j]`都加上value

**算法核心思想：**

1. 计算差分数组

   - ```c++
     diff[0]=nums[0];
     // [i,j,val]对nums[i]到nums[j]加val
     diff[i]+=val;
     if(j<nums.size()) // 如果j>=数组长度,则表示从[i,end]都加val
         diff[j+1]-=val; 
     ```

   - `diff`数组跟`nums`数组长度一样，`diff`数组首元素跟`nums`数组首元素相同

   - *注意`diff[j+1]-=val;`时，必须先判断数组长度跟j的大小*

2. 由差分数组计算变化后的数组

   ```c++
   nums[0]=diff[0];
   for(int i=0;i<nums.size();i++)
       nums[i]=nums[i-1]+diff[i];
   ```

**例题：**

- [1109]()：简单的差分数组
- [1094]()：





 
