---
title: Windows下必要软件，安装及使用笔记
date: 2021-11-05 13:11:33
tags:
- Windows
- Tools
---

> 展示一些Windows系统下，常用的一些软件的安装、使用发放和一些常见问题的解决方式。

<!--more-->

1. [WSL安装及使用](https://timemeansalot.github.io/2021/06/26/WSL_Config/)
2. [Vs Code安装及使用](https://timemeansalot.github.io/2021/06/26/VSCode/)

# Power Shell代理
```
$Env:http_proxy="http://172.19.48.1:7890";$Env:https_proxy="http://172.19.48.1:7890"
```

# 安装scoop
scoop是Windows 10下的包管理软件，类似于macOS的brew以及Linux下的apt。
1. 更改hosts，否则不能访问scoop服务器
   更改目录为`C:\WINDOWS\system32\drivers\etc`下的hosts文件，添加如下内容
   ```
   # >>> change hosts >>>
   127.0.0.1 localhosts #loopback
   199.232.4.133 raw.githubusercontent.com
   # <<< change hosts <<<
   ```
2. 更改scoop安装到D盘
   管理员身份打开power shell，输入命令：
   ```
   $env:SCOOP='D:\SystemSoftwares\scoop'
   [Environment]::SetEnvironmentVariable('SCOOP', $env:SCOOP, 'User')
   ```
   如果安装成功之后，可以执行`scoop help`查看scoop大致用法
3. *更改scoop下载的软件的安装位置*. (PS:这个指令好像没有用，貌似第二部的制定的安装位置，会决定后续scoop下载的软件的安装位置为scoop安装目录下的apps文件夹)
   ```
   $env:SCOOP_GLOBAL='D:\SystemSoftwares\scoopApps'
   [Environment]::SetEnvironmentVariable('SCOOP_GLOBAL', $env:SCOOP_GLOBAL, 'Machine')
   # run the installer
   iex (new-object net.webclient).downloadstring('https://get.scoop.sh')
   ```
4. 配置scoop源为gitee，提升软件下载速度
   ```
   scoop config SCOOP_REPO https://gitee.com/squallliu/scoop
   scoop update
   ```
5. 常见是scoop语法
   - search
   - install
   - update
   - status
   - uninstall
   - info
   - home
  比如，下面展示通过scoop安装hyper terminal的过程