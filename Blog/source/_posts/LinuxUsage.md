---
title: LinuxUsage
date: 2021-11-05 13:23:26
tags:
- Linux
- Tools
---

![](https://i.loli.net/2021/11/05/jH8LPZJcR5eBntI.png)
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

# 配置PicGo
> PicGo是一个图片上传工具，它可以快速地将本地图片上传到图床，并且返回对应的URL。
1. 获取PicGo：`npm install picgo -g`
2. 设置上传图床：`picgo set uploader`

# 配置代理
在Windows下使用代理软件实现科学上网之后，想要在WSL2下使用代理。按照如下方式配置：
```
export https_proxy='http://172.19.48.1:7890'
export http_proxy='http://172.19.48.1:7890'
```
其中`172.19.48.1`是主机的ip，`7890`是运行在Windows上的代理软件的*代理端口*。
切记，不要使用socks5进行代理，貌似在WSL中，使用socks5代理不起作用，至少我在配置的时候就是这样的。

测试代理是否成功：`curl ip.sb`如果可以正常返回代理服务器的IP地址，则说明代理已经成功；如果是没有任何响应，则代表代理失败。

# 美化WSL终端
在Windows下调用WSL，默认的终端很难看，所以需要我们自己美化一下，美化后的结果如图：
![](https://i.loli.net/2021/11/13/X1oLZnqbSdcTz5y.png)
需要用的的东西如下：
- Hyper：一个跨平台的终端
- oh-my-zsh：一个可以高度定制化的shell用于替代Linux里自带的bash

安装步骤[参考链接](https://sspai.com/post/56081)

# 默认打开ssh-agent和ssh-add
在`.bashrc`或者`.zshrc`末尾添加如下配置文件：
```
# >>> ssh initialize >>>
source ~/.ssh/auto_start_ssh.sh
# <<< ssh initialize >>> 
```
其中auto_start_ssh.sh文件放在.ssh目录下，它的内容如下：
```
#!/bin/bash

ps -aux | grep ssh-agent | grep -v grep > /dev/null
if [ $? != 0 ]; then
#       echo "ssh-agent is not running, so start it!"
        ssh-agent > ~/.ssh/ssh_agent_var.sh
        source ~/.ssh/ssh_agent_var.sh > /dev/null
        ssh-add ~/.ssh/pc_wsl > /dev/null 2>&1
else
#       echo "ssh-agent is already running!"
        source ~/.ssh/ssh_agent_var.sh > /dev/null
        ssh-add ~/.ssh/pc_wsl > /dev/null 2>&1
fi
```
> 这样每次打开WSL的时候，会自动打开ssh-agent并且添加ssh-key了，然后就可以直接访问GitHub了。