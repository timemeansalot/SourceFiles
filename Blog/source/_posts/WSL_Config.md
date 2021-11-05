---
title: wsl_config
date: 2021-03-23 13:34:43
tags: wsl
---



Windows利用WSL配置Linux开发环境的详细教程

[[_TOC_]]

<!--more-->

# 在WSL中安装Ubuntu-20.04
1. 根据Microsoft的官方教程，在Windows上打开subsystem功能、虚拟化功能，[教程地址](https://docs.microsoft.com/en-us/windows/wsl/install-manual)。PS：最后教程里会叫我们从Windows的AppStore里下载对应的Linux版本安装，不要执行这个步骤，因为这样默认Linux是安装到C盘的
2. 下载Ubuntu-20.04的**appx**文件：在教程页面最下面，Microsoft给出了[下载地址](https://aka.ms/wslubuntu2004)，下载Ubuntu 20.04。
3. 解压安装：更改下载文件的后缀为zip，将其解压到D盘，执行目录下的Ubuntu安装文件，就会将Ubuntu安装到解压目录下了。

# 在Power Shell中操作WSL
1. 查看WSL状态：`wsl -l -v`
2. 关闭WSL：`wsl shutdown`
3. 设置wsl2：`wsl --set-version Ubuntu-20.04 2`
4. 设置默认为wsl2：`wsl --set-default-version 2`


# WSL mount 磁盘

```bash
在windows 下移动硬盘位 z

在ubuntu 下输入命令：
sudo mkdir /mnt/z
(此命令为在 Windows 下新建一个 Z盘,访问 windows 下的文件 cd /mnt/z)

挂载盘符 z
sudo mount -t drvfs z: /mnt/z

最后，输入 mnt/Z 和windows 下是一模一样的