---
title: Ubuntu20.04 配置记录
date: 2023-08-30 13:15:57
tags: Tools
---

[TOC]

<!--more-->

# ubuntu安装

1. 从[ubuntu官网](https://cn.ubuntu.com/download)或者[国内镜像网站](https://mirrors.tuna.tsinghua.edu.cn/ubuntu-releases/22.04.3/)下载ubuntu iso镜像
2. 烧录镜像到u盘以制作安装盘，可以通过[refus](https://rufus.ie/downloads/)或者[etcher](https://etcher.balena.io/)来烧录镜像到u盘
3. 重启电脑，进入到bios，设置u盘为第一启动项，从u盘进入到ubuntu安装界面，完成ubuntu安装

# ubuntu好用的应用软件

1. 切换软件源为[清华大学软件源](https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu/)，从而加速国内安装软件的速度
2. optional：安装NVIDIA驱动从而避免屏幕卡顿:`sudo ubuntu-drivers autoinstall && sudo reboot now`
3. 安装搜狗输入法，按照[官网教程](http://pinyin.sogou.com/linux/help.php)安装即可
4. 安装[chrome](https://www.google.com/chrome/)
5. 配置ssh，保证你可以从github上正常地下载软件
6. 安装[vscode](https://code.visualstudio.com/download)，下载deb文件通过`sudo dpki -i xxx.deb`安装即可
7. 安装[typora](https://github.com/iuxt/src/releases/download/2.0/Typora_Linux_0.11.18_amd64.deb)，下载deb文件通过`sudo dpki -i xxx.deb`安装即可
8. 安装微信，参考[这个教程](https://blog.csdn.net/me_yundou/article/details/129581550)，
   主要从[优麒麟官网](https://archive.ubuntukylin.com/software/pool/partner/)下载wine跟wechat的安装包，然后通过命令`sudo apt install -f -y ./xxxx.deb`来安装

# 配置RISC-V开发环境

通过终端安装软件的时候，**可以打开终端代理**：

```bash
export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890
```

**重点**：下面的代码可以通过下载[该脚本](https://github.com/timemeansalot/env_config/blob/linux/env-install-scripts.sh)、使用命令`zsh env-install-scripts.sh`一键安装

## 安装一些需要的库、软件

```bash
    sudo apt update
    sudo apt install proxychains4 shadowsocks-libev vim wget git tmux make gcc time curl libreadline6-dev libsdl2-dev gcc-riscv64-linux-gnu openjdk-11-jre zlib1g-dev device-tree-compiler flex autoconf bison sqlite3 libsqlite3-dev -y
    sudo apt-get install git perl python3 make autoconf g++ flex bison clang -y
    sudo apt-get install libgoogle-perftools-dev numactl perl-doc -y
    sudo apt-get install libfl2 -y # Ubuntu only (ignore if gives error)
    sudo apt-get install libfl-dev -y # Ubuntu only (ignore if gives error)
    sudo apt-get install zlibc zlib1g zlib1g-dev -y  # Ubuntu only (ignore if gives error)

    sudo apt-get install git help2man perl python3 make autoconf g++ flex bison ccache -y
    sudo apt-get install libgoogle-perftools-dev numactl perl-doc -y
    sudo apt-get install libfl2 -y  # Ubuntu only (ignore if gives error)
    sudo apt-get install libfl-dev -y  # Ubuntu only (ignore if gives error)
    sudo apt-get install zlibc zlib1g zlib1g-dev -y  # Ubuntu only (ignore if gives error)
    sudo apt-get install help2man -y
    sudo apt-get install build-essential -y    # build-essential packages, include binary utilities, gcc, make, and so on
    sudo apt-get install man -y                # on-line reference manual
    sudo apt-get install gcc-doc -y            # on-line reference manual for gcc
    sudo apt-get install gdb -y                # GNU debugger
    sudo apt-get install git -y                # revision control system
    sudo apt-get install libreadline-dev -y    # a library used later
    sudo apt-get install libsdl2-dev -y        # a library used later
    sudo apt-get install llvm llvm-dev -y      # llvm project, which contains libraries used later
    # sudo apt-get install llvm-11 llvm-11-dev # only for ubuntu20.04

    sh -c "curl -L https://github.com/com-lihaoyi/mill/releases/download/0.9.8/0.9.8 > /usr/local/bin/mill && chmod +x /usr/local/bin/mill"
```

## 安装Verilator

在终端里执行下述所有代码、或者执行[这个脚本]()。
你可以指定verilator的版本以及默认的编译器

```bash
    # https://verilator.org/guide/latest/install.html


    git clone https://github.com/verilator/verilator

    # Every time you need to build:
    unset VERILATOR_ROOT  # For bash
    cd verilator

    # XiangShan uses Verilator v4.218
    # git checkout v4.218

    autoconf        # Create ./configure script
    # Configure and create Makefile
    # ./configure CC=clang CXX=clang++ # We use clang as default compiler
    ./configure
    # make -j8        # Build Verilator itself
    make -j `nproc`        # Build Verilator itself
    sudo make install

    verilator --version
```

顺手安装一个gtkwave: `sudo apt-get install gtkwave -y`

## 安装RISC-V编译工具链

> 要下载很多Github上的仓库，所以要保证你的终端可以从Github上下载

```bash
    sudo apt-get install autoconf automake autotools-dev curl python3 python3-pip libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev ninja-build git cmake libglib2.0-dev -y
    git clone https://github.com/riscv/riscv-gnu-toolchain
    cd riscv-gnu-toolchain
    # git submodule update --init --recursive
    ./configure --prefix=/opt/riscv # prefix后面跟的是您设置的riscv工具链的安装路径，可以自行选择
    # compile newlib
    make -j `nproc`
    # compile riscv-toolchain
    make linux -j `nproc`
```

## 安装Scala, Mill & SBT

TBD

# 安装输入工具

## 安装NodeJS

```bash
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
source ~/.zshrc
# nvm ls-remote
nvm install 18
source ~/.zshrc
npm config set registry https://registry.npm.taobao.org
# install hexo
npm install hexo -g
npm fund
npm install
sudo apt-get install pandoc -y # used by hexo
```

## 安装NVIM, TMUX

1. 从Github下载nvim, tmux, zsh的配置文件
   ```bash
      sudo apt install stow -y
      cd ~
      git clone git@github.com:timemeansalot/env_config.git .env_config
      cd .env_config
      stow nvim && stow tmux && stow zsh
   ```
2. 下载工具: `sudo apt install tmux -y`
3. install nerd font
   - download nerd font
   - extract nerd font to `~/.local/share/fonts`
   - refresh fonts: `fc-cache -fv`
   - config your editor to use nerd font
4. 配置zsh，一个更好用的shell工具
   ```bash
    sudo apt install zsh -y
    chsh -s /usr/bin/zsh
    sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    p10k configure
   ```
5. 配置tmux

   - 安装tmux包管理工具: `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`
   - 从Github上下载配置文件并应用: `cd ~/.env_config && stow tmux`
   - 进入tmux: `tmux new -s test`
   - 启用配置文件: ctrl+d+I

6. 配置neovim
   - 安装nvim
     ```bash
         wget https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.tar.gz
         mkdir ~/app
         tar -xvzf nvim-linux64.tar.gz -C ~/app
         sudo ln -s ~/app/nvim-linux64/bin/nvim /usr/bin/nvim
         nvim --version
     ```
   - 配置neovim
     ```bash
        # config neovim
        sudo apt-get install ripgrep -y
        sudo apt install cargo -y
        cargo install stylua # lua formatter
        cargo install svls   # system verilog lsp
        sudo apt remove cmdtest
        sudo apt remove yarn
        npm install -g prettier # used by neovim
        npm install picgo -g # install picgo-core
        picgo set uploader
        npm install -g yarn
        cd ~/.local/share/nvim/site/pack/packer/start/
        git clone https://github.com/iamcco/markdown-preview.nvim.git
        cd markdown-preview.nvim
        yarn install
        yarn build
     ```
