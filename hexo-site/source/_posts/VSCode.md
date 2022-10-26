---
title: Deepin开发环境配置，VSCode配置
date: 2022-06-26 23:38:57
tags:
    - Deepin
    - VSCode
---



配置Deepin和VSCode的开发环境

<!--more-->



# Deepin的配置

1. git

   ```bash
   sudo apt install git
   ```

   

2. c++

   ```bash
   sudo apt install build-essential
   ```

   

3. python

   ```bash
   # 安装conda
   wget https://repo.anaconda.com/miniconda/Miniconda3-py39_4.12.0-Linux-x86_64.sh
   sudo bash Miniconda3-py39_4.12.0-Linux-x86_64.sh
   # 配置清华源
   conda config --set show_channel_urls yes
   # 替换成如下内容
   channels:
     - defaults
   show_channel_urls: true
   default_channels:
     - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
     - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
     - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2
   custom_channels:
     conda-forge: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
     msys2: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
     bioconda: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
     menpo: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
     pytorch: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
     simpleitk: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
   
   # 清除缓存
   conda clean -i
   
   # 创建一个环境
   conda create -n learn
   conda activate learn
   
   # 安装jupyter
   conda install jupyter
   
   # 配置jupyter
   jupyter notebook --generate-config
   # 取消token，设置默认打开的文件夹
   # 定位到c.NotebookApp.token,将等号后面的'<generated>'改为''即可
   # 找到c.NotebookApp.notebook_dir，将其后面的值改成目标目录即可
   ```

   

4. nvm, node

   ```bash
   # 安装nvm
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash
   # 配置nvm源
   echo "export NVM_NODEJS_ORG_MIRROR=http://npm.taobao.org/mirrors/node" >> ~/.bashrc
   echo "NVM_IOJS_ORG_MIRROR=http://npm.taobao.org/mirrors/iojs" >> ~/.bashrc
   source ~/.bashrc
   # 安装nodejs
   nvm install node
   # 配置nodejs源
   npm config set registry https://registry.npm.taobao.org
   # 使用nodejs安装hexo
   npm install -g hexo-cli
   ```

   

5. java, scala, chisel

6. matlab

7. docker

8. chrome

9. wechat, wsp, typora, netease music, chrome, vscode

10. clash

11. davinci



# VSCode的配置

1. [Matlab配置](https://zhuanlan.zhihu.com/p/38178015)
2. 
