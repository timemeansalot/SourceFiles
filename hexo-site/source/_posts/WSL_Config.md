---
title: wsl_config
date: 2021-03-23 13:34:43
tags: wsl
---



Windows利用WSL配置Linux开发环境的详细教程



<!--more-->
# Windows下配置WSL 2开发环境

## 1 下载安装WSL到非系统盘

1.  根据[Microsoft官方教程](https://docs.microsoft.com/en-us/windows/wsl/install-manual)，在Windows上开始WSL（Windows subsystem for Linux）功能。最后一步的时候，教程里叫我们在应用商店里安装Linux。***不要***执行该步骤，因为从应用商店里安装会默认安装到C盘，但是我们不想要安装到系统盘。

2.  在Power Shell中控制WSL有如下常用命令：

    *   `查看WSL状态：wsl -l -v`

    *   `关闭WSL：wsl shutdown`

    *   `设置wsl2：wsl --set-version Ubuntu-20.04 2`

    *   `设置默认为wsl2：wsl --set-default-version 2`

3.  &#x20;从Microsoft官网下载Linux安装包，比如[Ubuntu-20.04的安装包](https://aka.ms/wslubuntu2004)。下载之后将安装包后缀改成`.zip`并且解压到D盘，此时可以看到Ubuntu20.04的安装文件，点击运行该安装文件，可以将Ubuntu安装到解压包所在的位置。

    > 通过以上步骤，我们实现了在Windows上开始WSL功能，并且安装到D盘

4.  Linux下挂在Windows硬盘，并且指定硬盘格式的方法：

    在windows 下移动硬盘位 z

    在ubuntu 下输入命令：\
    `sudo mkdir /mnt/z`\
    (此命令为在 Windows 下新建一个 Z盘,访问 windows 下的文件 cd /mnt/z)

    挂载盘符 z\
    `sudo mount -t drvfs z: /mnt/z`

## 2 配置WSL

### 2.1 配置WSL使用国内镜像

1.  更换Ubuntu使用阿里云镜像，从而加快软件下载速度

    ```bash
    # 1. 备份之前的源
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
    # 2. 替换为阿里云的源
    sudo vim /etc/apt/source.list

    ```

2.  将bashrc中替换为如下内容：

    ```bash
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

3.  最后更新软件即可：

    ```bash
    sudo apt update && sudo apt upgrade -y
    ```

### 2.2 配置WSL使用代理，访问国外网站

默认情况下WSL不能访问一下国外的网站，即使我们的Windows主机已经实现了科学上网。所以我们在使用代码安装软件的时候，可能会失败。

1.  在Windows的CMD窗口中获得本机的IP地址，在CMD中使用指令: `ipconfig`

2.  在WSL中手动开始代理：

    ```bash
    export https_proxy='http://xx.xx.xx.xx:7890'
    export http_proxy='http://xx.xx.xx.xx:7890' # 其中xx.xx.xx.xx是Windows下在cmd中查看到的ipv4地址，注意替换
    ```

3.  将代理永久配置到.zshrc中

    ```bash
    vim .zshrc
    ```

    在文件末尾添加如下内容：

    ```bash
    # >>> set proxy >>>
    host_ip=$(cat /etc/resolv.conf |grep "nameserver" |cut -f 2 -d " ")    
    alias proxy="export http_proxy=http://$host_ip:7890 && export https_proxy=http://$host_ip:7890"
    alias unproxy="unset http_proxy && unset https_proxy"
    # <<< set proxy <<<
    ```

    ```bash
    source .zshrc
    ```

### 2.3 安装oh-my-zsh
[参考链接: 打造高颜值终端——Hyper](https://sspai.com/post/56081)

> zsh是跟bash差不多的Linux下的命令行shell，oh-my-zsh在zsh上进行了封装，从而可以打造更加精美的终端

1.  备份.bashrc

    ```bash
    cd ~
    sudo cp .bashrc .bashrc_bak
    ```

2.  安装oh-my-zsh

    ```bash
    # 安装zsh
    sudo apt install zsh
    ```

3.  安装oh-my-zsh

    ```bash
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    ```

4.  在使用了oh-my-zsh之后，就不是使用的bash了，所以以后不要用`source .bashrc`，而是要用`source .zshrc`

### 2.4 安装node

> Linux下很多工具都需要使用到node，比如Hexo，Picgo等。通过nvm来管理node

1.  安装nvm并且刷新zsh

    ```bash
    curl -o- <https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh> | bash
    # 刷新.zshrc
    source .zshrc
    # 查看nvm
    nvm -v
    ```

2.  更换nvm为国内镜像，在.zshrc中末尾添加如下内容

    ```bash
    export NVM_NODEJS_ORG_MIRROR=http://npm.taobao.org/mirrors/node
    export NVM_IOJS_ORG_MIRROR=http://npm.taobao.org/mirrors/iojs
    ```

    刷新zsh: `source .zshrc`

3.  安装nodejs

    *   查看所有可以安装的nodejs版本信息：`nvm ls-remote`

    *   安装对应版本的nodejs，这里安装nodejs12：`nvm install 12`

    *   查看本地的nodejs版本：`nvm list`

4.  配置npm源
    在第三步中，会安装nodejs12和对应的npm（npm是nodejs的包管理软件）。我们需要配置npm使用淘宝源，这样npm在安装包的时候，会从淘宝镜像下载，从而大幅提高国内的下载速度。

    ```bash
    npm config set registry https://registry.npm.taobao.org # 替换npm使用淘宝镜像
    npm config get registry # 查看npm当前使用的镜像，应该会考到npm现在已经使用淘宝镜像了
    ```

5.  测试npm能否从淘宝镜像拉取\
    我们这里安装一个nodejs包**hexo**（是一个静态的博客搭建框架）

    ```bash
    npm install -g hexo-cli # -g参数表示在全局安装 hexo_cli
    ```

6.  安装PicGO，一个图片上传软件

    ```bash
    # 获取PicGo
    npm install picgo -g
    # 设置上传图床
    picgo set uploader
    ```

### 2.5 配置GitHub的ssh

1.  创建ssh key并且连接到GitHub

2.  在zshrc末尾添加以下文件，这样wsl会默认打开ssh-agent

    ```bash
    # >>> ssh initialize >>>
    source ~/.ssh/auto_start_ssh.sh
    # <<< ssh initialize >>>
    ```

3.  其中auto\_start*ssh.sh文件放在.ssh目录下，它的内容如下：注意将pc\_wsl改成自己ssh*\_key文件的名称

    ```bash
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

    这样每次打开WSL的时候，会自动打开ssh-agent并且添加ssh-key了，然后就可以直接访问GitHub了。
