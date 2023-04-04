---
title: Git使用过程中的笔记 
date: 2022-10-11 09:24:03
tags: Tools
---
![git usage](https://s2.loli.net/2023/04/03/Y5g8TqKika4sJxM.png)

# 删除本地所有的修改，跟远程仓库的代码保持一致
```bash
git fetch --all
git reset --hard origin/master
git clean -fd
git pull
```
