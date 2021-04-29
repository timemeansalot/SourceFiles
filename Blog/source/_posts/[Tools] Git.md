---
title: git-notes
date: 2021-03-16 12:26:01
tags: 
	- Git
	- Tools
---





# Git配置

配置Git本地仓库的用户名和邮箱（优先于全局仓库和邮箱）

```bash
git config --local user.name 'Jfu'
git config --local user.email 'xxxxx@xx'
```

配置Git全局的用户名和邮箱

```bash
git config --global user.name 'Jfu'
git config --global user.email 'xxxxx@xx'
```

删除用户名和邮箱

```bash
git config --local -e # -e 可以edit配置文件，删除对应的用户名和密码即可
git config --global -e
```

