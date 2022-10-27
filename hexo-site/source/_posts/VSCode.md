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
   sudo apt install git -y
   ```

   

2. c++

   ```bash
   sudo apt install build-essential -y
   ```

   

3. python

   ```bash
   # 安装conda
   wget https://repo.anaconda.com/miniconda/Miniconda3-py39_4.12.0-Linux-x86_64.sh
   sudo bash Miniconda3-py39_4.12.0-Linux-x86_64.sh
   
   # conda init
   cd /opt/miniconda3/bin
   ./conda init
   source ~/.bashrc
   
   # 配置清华源
   conda config --set show_channel_urls yes
   vim .condarc
   
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
   vim ~/.jupyter/jupyter_notebook_config.py
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

   1. JDK is short for Java Development Kits, as described before Scala has to run in JVM.
       ```bash
       sudo apt install openjdk-11-jdk
       ```
   2. Install sbt, sbt is a build tool for Scala. SBT can be used to
       - Compile Scala projects
       - Download libraries for Scala, for example sbt can download Chisel jars automatically.

       We can't just use `apt install sbt` to install sbt, because Ubuntu's official repository doesn't have sbt. Use the following commands to install sbt on Ubuntu. [The official installation guide for SBT](https://www.scala-sbt.org/1.x/docs/Installing-sbt-on-Linux.html).
       ```bash
       sudo apt-get update
       sudo apt-get install apt-transport-https curl gnupg -yqq
       echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | sudo tee /etc/apt/sources.list.d/sbt.list
       echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | sudo tee /etc/apt/sources.list.d/sbt_old.list
       curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | sudo -H gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/scalasbt-release.gpg --import
       sudo chmod 644 /etc/apt/trusted.gpg.d/scalasbt-release.gpg
       sudo apt-get update
       sudo apt-get install sbt
       ```
   3. Check if your enviroment is OK
       ```bash
       javac --version # should output some info about java
       java --version  # should output some info about javac
       sbt             # should enter sbt shell, ctrl+C to quit
       ```
       We can also run a chisel-example to check Scala works well.
       ```bash
       git clone https://github.com/schoeberl/chisel-examples.git
       cd chisel-examples/hello-world/
       ```
       hello-world is a self contained minimal project for a blinking LED in an FPGA. You can find the chisel codes under `src` folder.
       Use the following code to do a Chisel Test, it should output blinking in terminal.
       ```bash
       sbt test
       ```
       
       

6. gtkwave, verilator

   ```bash
   apt-get install verilator gtkwaves
   ```

   

7. smatlab

8. [Latex](https://kz16.top/deepin/#latex%E7%9A%84%E5%AE%89%E8%A3%85)

   ```bash
   # 安装texlive-full
   sudo apt install texlive-full -y
   ```

   接下来要安装LaTex的编辑器，可以去[官网下载Tex Studio](http://texstudio.sourceforge.net/)，s但是我更喜欢使用VSCode，只需要在VSCode中添加LaTex扩展即可。

9. docker

   1. sogou input, wechat, wsp, typora, netease music, chrome, vscode, chrome, Artha: 直接在app store下载

10. [clash](https://www.jianshu.com/p/02e3e8ccfe80)

11. ~~davinci~~：安装了，用不了。好像是AMD GPU驱动的问题。

    1. ~~官网下载安装Davinci，按照安装PDF里面的说明，安装即可~~
    2. ~~[安装AMD驱动](https://bbs.deepin.org/post/233022).~~
       1. 使用flowblade替代：`sudo apt-get install flowblade`

12. GIMP

    1. 应用商店安装GIMP（类似Photoshop）
    2. 安装darktable（类似Lightroom）用作编辑raw文件: `sudo apt install darktables`




# VSCode的配置

1. [Matlab配置](https://zhuanlan.zhihu.com/p/38178015)
2. C++配置
   1. C/C++
3. Python配置
   1. Python
   2. Jupyter
4. Java/Scala/Chisel配置
   1. Scala (Metals)
   2. Scala Syntax
5. Latex
   1. LaTeX Workshop：安装了这个插件之后，可以通过vscode编译latex文件了s
   2. Markdown All in One
