---
title: Deepin开发环境配置，VSCode配置
date: 2022-06-26 23:38:57
tags:
  - Deepin
  - VSCode
---

![deepin](https://s2.loli.net/2023/04/10/dbNlzX1ok7Dhp5w.png)
配置 Deepin 和 VSCode 的开发环境

<!--more-->

# Deepin 的配置

## git

```bash
sudo apt install git -y
```

## c++

```bash
sudo apt install build-essential -y
```

## python

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

## nvm, node

```bash
# 安装nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash
# 配置nvm源
echo "export NVM_NODEJS_ORG_MIRROR=http://npm.taobao.org/mirrors/node" >> ~/.bashrc
echo "export NVM_IOJS_ORG_MIRROR=http://npm.taobao.org/mirrors/iojs" >> ~/.bashrc
source ~/.bashrc
# 安装nodejs
nvm install node
# 配置nodejs源
npm config set registry https://registry.npm.taobao.org
# 使用nodejs安装hexo
npm install -g hexo-cli
```

## PicGo

[参考链接](https://picgo.github.io/PicGo-Core-Doc/zh/guide/).

```bash
# 使用npm安装picgo
npm install picgo -g

# 设置picgo使用smms
picgo use

# 设置smms的token
picgo set uploader

# 设置终端代理
export https_proxy=http://127.0.0.1:7890;export http_proxy=http://127.0.0.1:7890
sexport all_proxy=socks5://127.0.0.1:7890
# 在终端中测试picgo上传图片
picgo u picture_path
```

## java, scala, chisel

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
4. 在 Jupyter Notebook 中配置 Scala Kernel

   ```bash
   # 卸载之前的kernel
   rm -rf ~/.local/share/jupyter/kernels/scala/

   # 安装Scala Kernel
   curl -L -o coursier https://git.io/coursier-cli && chmod +x coursier
   SCALA_VERSION=2.12.10 ALMOND_VERSION=0.9.1
   ./coursier bootstrap -r jitpack \
       -i user -I user:sh.almond:scala-kernel-api_$SCALA_VERSION:$ALMOND_VERSION \
       sh.almond:scala-kernel_$SCALA_VERSION:$ALMOND_VERSION \
       --sources --default=true \
       -o almond
   ./almond --install
   ```

## gtkwave, verilator

```bash
sudo apt-get install verilator gtkwave
```

## matlab

1. 去官网下载安装 Matlab，安装到/opt/下即可，安装的时候需要选择以下 6 个组件。安装的时候，勾选把 matlab 命令添加到/usr/bin，这样可以直接在终端中打开 MATLAB.

   - MATLAB
   - Audio Toolbox
   - Control System Toolbox
   - DSP System Toolbox
   - Signal Processing Toolbox
   - Symbolic Math Toolbox

2. [设置 Matlab 的放大比例](https://www.jianshu.com/p/af284657e09e)，Maltab 默认设置在 Linux 的高清屏下字体显示会太小, 在 matlab 中输入以下命令并重启。

   ```matlab
   s.matlab.desktop.DisplayScaleFactor.PersonalValue = 2
   ```

3. 设置 MATLAB 图标，下载对应的[matlab_logo.png](https://drive.google.com/file/d/1EH_f9wa-mP1RMdM1yPNXPH9WzRPm5zzo/view)

   ```bash
   # 添加desktop文件
   sudo vim /usr/share/applications/matlab.desktop

   # 添加如下信息
   [Desktop Entry]
   Name=MATLAB R2022b
   Comment=MATLAB R2022b software
   Exec=/opt/MATLAB/R2022b/bin/matlab -desktop
   Icon=/opt/MATLAB/R2022b/matlab_logo.png
   Terminal=false
   Type=Application
   Category=Development;Simulation;Education;Science;
   StartupNotify=true
   Keywords=Run;

   # 从matlab_logo.png移到对应目录
   ```

## [Latex](https://kz16.top/deepin/#latex%E7%9A%84%E5%AE%89%E8%A3%85)

```bash
# 安装texlive-full
sudo apt install texlive-full -y
# 安装中文字体
sudo apt install latex-cjk-all
```

接下来要安装 LaTex 的编辑器，可以去[官网下载 Tex Studio](http://texstudio.sourceforge.net/)，s 但是我更喜欢使用 VSCode，只需要在 VSCode 中添加 LaTex 扩展即可。

在 Deepin 的终端中打开文件的命令是`dde-file-manager`，后面跟需要打开的文件的路径即可。

## docker

## app store 下载的应用

sogou input, wechat, wsp, typora, netease music, chrome, vscode, chrome, Artha

## 添加微软字体

1. 如果安装了双系统，去 C 盘下面的 Windows 目录下，把 fonts 文件夹复制过来。

   打开 deepin 的字体管理器（font manager），选择添加字体，将 fonts 文件夹里面的内容全选添加即可，重启 WPS 就可以使用宋体等字体了。

   <img src="https://s2.loli.net/2022/11/14/ztldqOh12c8QVLC.png" alt="image-20221114183921285" style="zoom:50%;" />

2. 手动添加字体到 WPS 字体库，**这一步可能是不需要的**，因为上一步安装了字体到系统之后，WSP 应该是可以搜索到系统字体的，此步只做记录。

   ```bash
   mv Fonts/ /usr/share/fonts/wps-office/
   ```

3. 更改 WPS 为中文界面：在 deepin 中，如果你选择的系统语言是英文，那么你的 WPS 也会是英文界面，此时看不到字号“五号“这样的类型，也看不到“黑体”。需要将 WPS 的显示界面改正中文。

   ![image-20221114210116459](https://s2.loli.net/2022/11/14/ZNWgMnYvOzPkhCs.png)

​ 如果看不到上面的显示中文选项，需要安装 WPS 中文包: `sudo pacman -S wps-office-mui-zh-cn`。或者从百度进入官网下载 WPS 中文版也可以。

## clash

到 Github 下载[windows-Linux](https://github.com/Fndroid/clash_for_windows_pkg/releases)版本，安装到 opt 即可

## ~~davinci~~：安装了，用不了。好像是 AMD GPU 驱动的问题。

1. ~~官网下载安装 Davinci，按照安装 PDF 里面的说明，安装即可~~
2. ~~[安装 AMD 驱动](https://bbs.deepin.org/post/233022).~~
   1. 使用 flowblade 替代：`sudo apt-get install flowblade`

## Foxit PDF Reader

1. 在官网下载安装包进行安装
2. 字体在 Linux 下太小, TBD

## Mail

系统自带的 Mail，连接上科大时的配置如下：

1. incoming 使用 pop3
2. outcoming 使用 imap

<img src="https://s2.loli.net/2022/10/28/ZNca3bR2UnWLSCv.png" alt="image-20221028122824248" style="zoom:50%;" />

# VSCode 的配置

> 建议开启 VSCode 的同步功能，可以同步所有的设置、插件等信息

## [Matlab 配置](https://zhuanlan.zhihu.com/p/38178015)

## C++配置

1. C/C++

## Python 配置

1. Python
2. Jupyter

## Java/Scala/Chisel 配置

1. Scala (Metals)
2. Scala Syntax

## Latex

1. LaTeX Workshop：安装了这个插件之后，可以通过 vscode 编译 latex 文件了。**插件的 Recipe 选择：xe->bib->xe->xe 或者 pdf->bib->pdf->pdf**，可以编译参考文献。
2. Markdown All in One
