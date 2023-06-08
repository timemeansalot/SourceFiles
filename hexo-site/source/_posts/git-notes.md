---
title: Git使用过程中的笔记
date: 2022-10-11 09:24:03
tags: Tools
---

# 删除本地所有的修改，跟远程仓库的代码保持一致

```bash
git fetch --all
git reset --hard origin/master
git clean -fd
git pull
```

# 参考资料

1. [Git 开发流程和规范](https://git-man.tanghaojin.site/%E5%BC%80%E5%8F%91%E6%B5%81%E7%A8%8B%E5%92%8C%E8%A7%84%E8%8C%83.html)
2. [Git 进阶操作](https://git-man.tanghaojin.site/%E8%BF%9B%E9%98%B6%E6%93%8D%E4%BD%9C.html)
3. [Git Merge from bitbucket](https://www.atlassian.com/git/tutorials/using-branches/git-merge#:~:text=Git%20merge%20will%20combine%20multiple,used%20to%20combine%20two%20branches.)
