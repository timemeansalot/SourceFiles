---
title: 找工作小抄
date: 2023-07-19 11:22:00
tags: Job
password: goodluck
---

找工作时的记录

<!--more-->

# 公司职位信息

# 面试题总结

## 关键路径

定义：时序分析中，最长的路径
降低关键路径的方法：

1. 在比较长的路径上插入寄存器
2. 平衡寄存器：让寄存器在路径上尽可能均匀地分布
3. 优化表达式，例如乘法树优化，`a*b*c*`优化为`(a*b)*(c*d)`
4. 避免很大的fan out：fan out过大导致布局布线的时候，布线长度更长，从而导致延时更大
5. 在没有优先级的时候，使用case避免if-else
6. 关键信号后移：尽可能最后接入，从而减少其影响的地方

[参考资料](https://mp.weixin.qq.com/s?__biz=MzkxNzM0NDQ1OQ==&mid=2247484206&idx=1&sn=cba8d216e54f0d7489d9f27b5ac4c8b1&chksm=c1435a8af634d39c1be44dbeec49835a0d492b707f70bb7103abf7c51f88745f7293eb3b13c2&scene=21#wechat_redirect)

## 异步FIFO

> 主要特点是：读写端口不在一个时钟域

同步FIFO内部使用一个计数器就可以表示空和满的状态，但是一步FIFO读写是不在一个时钟域的，异步FIFO可以很好地解决**跨时钟域**的问题
