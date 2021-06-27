---
layout: '[toosl]'
title: VSCode开发环境搭建
date: 2021-06-26 23:38:57
tags:
- Tools
- VSCode
---

> VSCode搭建C++和Verilog的开发环境



1. 安装VSCode和插件
2. 配置C++、C开发环境
3. 配置Verilog开发环境



# 一：安装VSCode

1. **安装VSCode**：直接百度或者打开此[链接](https://code.visualstudio.com/)可以进入到VSCode的官网，在下载界面中，可以选择对应自己操作系统版本的VSCode安装文件。

   ![image-20210627095304839](https://i.loli.net/2021/06/27/w1PguSedDMflW3B.png)

2. **安装VSCode扩展**：VSCode广受欢迎的重要原因之一就是在于VScode作为一个轻量级的编辑器，有一个广泛的插件市场，这样开发者可以针对其使用的开发语言选择对应的插件，既保证了软件的*轻量性*，又提供了*强大的性能*。

   插件的安装分为*在线安装*和*离线安装*。

   - 在线安装：VSCode内部集成了`Extension`模块，在此模块中可以在线搜索并且一键安装对应的插件

     ![image-20210627095840388](https://i.loli.net/2021/06/27/UczxELIgWpbhS2n.png)

   - 离线安装：加入您的电脑不能访问Internet，您可以在可以访问网络的电脑上下载对应的插件，拷贝到不能访问网络的电脑上，采用离线安装的方式进行安装。

     - 搜索插件：使用这个[链接](https://marketplace.visualstudio.com/)可以进入到VSCode插件市场，可以自由搜索自己需要的插件：

       ![image-20210627100410474](https://i.loli.net/2021/06/27/4VYWyMHgG79pZz2.png)

     - 下载插件：进入到插件页面之后，可以看到``Download`，点击即可下载对应插件

       ![image-20210627100842635](https://i.loli.net/2021/06/27/ORhSC9Tz4Wkmt1I.png)

     - 安装插件：在vscode中，可以选择离线插件进行安装，步骤如下：

       快捷键`ctrl+shift+p`呼出控制面板-->输入vsix，选择install from vsix-->选择下载好的插件离线包进行安装

       ![image-20210627101504102](../../../../../Pictures/TyporaPictures/image-20210627101504102.png)

       

       

     





# 二：配置C开发环境

1. 安装C环境

   - Ubuntu或者WSL下可以直接使用terminal安装C编译器和GDB（用于debug）

     ```bash
     sudo apt install gcc g++
     ```

   - Windows可以下载mingw64编译器：百度mingw64，下载解压版本的，解压到文件夹后，将bin目录添加到path

