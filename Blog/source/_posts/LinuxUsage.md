---
title: LinuxUsage
date: 2021-11-05 13:23:26
tags:
- Linux
- Tools
---

> 介绍我如何在Linux系统中，搭建编程开发环境

<!--more-->

# 更换Ubuntu-20.04 apt的源
```
# 1. 备份之前的源
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
# 2. 替换为阿里云的源
sudo vim /etc/apt/source.list
```
替换为如下内容：
```
deb http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
```

最后更新软件即可：
```
sudo apt update && sudo apt upgrade -y
```

# 安装NVM和NodeJS
1. 安装nvm
   ```
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
   source ~/.bashrc
   ```
   输入`nvm -v`可以看到对应的nvm信息
2. 更换nvm使用淘宝源，提升下载速度
   输入指令`vim ~/.bashrc`，在文件最末尾加入如下内容：
   ```
   export NVM_NODEJS_ORG_MIRROR=http://npm.taobao.org/mirrors/node
   export NVM_IOJS_ORG_MIRROR=http://npm.taobao.org/mirrors/iojs
   ```
   最后刷新bashrc：`source ~/.bashrc`
3. 安装nodejs
   - 查看所有可以安装的nodejs版本信息：`nvm ls-remote`
   - 安装对应版本的nodejs，这里安装nodejs12：`nvm install 12`
4. 配置npm源
   在第三步中，会安装nodejs12和对应的npm（npm是nodejs的包管理软件）。我们需要配置npm使用淘宝源，这样npm在安装包的时候，会从淘宝镜像下载，从而大幅提高国内的下载速度。
   ```
   npm config set registry https://registry.npm.taobao.org # 替换npm使用淘宝镜像
   npm config get registry # 查看npm当前使用的镜像，应该会考到npm现在已经使用淘宝镜像了
   ```
5. 测试npm能否从淘宝镜像拉取
   我们这里安装一个nodejs包**hexo**（是一个静态的博客搭建框架）。
   ```
   npm install -g hexo-cli
   ```
   可以看到npm从淘宝镜像下载了hexo包，速度十分快

