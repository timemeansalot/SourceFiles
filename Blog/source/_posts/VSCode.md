---
layout: '[toosl]'
title: VSCode开发环境搭建
date: 2021-06-26 23:38:57
tags:
- Tools
- VSCode
---

> VSCode搭建C++和Verilog的开发环境

![image-20210709081056366](https://i.loli.net/2021/07/09/Z9WaOU5gAiV3jIE.png)

<!--more-->

1. 安装VSCode和插件
2. 配置C++、C开发环境
3. 配置Verilog开发环境



# 一：安装VSCode

## （1）安装VSCode

直接百度或者打开此[链接](https://code.visualstudio.com/)可以进入到VSCode的官网，在下载界面中，可以选择对应自己操作系统版本的VSCode安装文件。

![image-20210627095304839](https://i.loli.net/2021/06/27/w1PguSedDMflW3B.png)

## （2）安装VSCode扩展

VSCode广受欢迎的重要原因之一就是在于VScode作为一个轻量级的编辑器，有一个广泛的插件市场，这样开发者可以针对其使用的开发语言选择对应的插件，既保证了软件的*轻量性*，又提供了*强大的性能*。

>  插件的安装分为*在线安装*和*离线安装*。

1. 在线安装：VSCode内部集成了`Extension`模块，在此模块中可以在线搜索并且一键安装对应的插件

   ![image-20210627095840388](https://i.loli.net/2021/06/27/UczxELIgWpbhS2n.png)

2. 离线安装：加入您的电脑不能访问Internet，您可以在可以访问网络的电脑上下载对应的插件，拷贝到不能访问网络的电脑上，采用离线安装的方式进行安装。

- 搜索插件：使用这个[链接](https://marketplace.visualstudio.com/)可以进入到VSCode插件市场，可以自由搜索自己需要的插件：

  ![image-20210627100410474](https://i.loli.net/2021/06/27/4VYWyMHgG79pZz2.png)

- 下载插件：进入到插件页面之后，可以看到``Download`，点击即可下载对应插件

  ![image-20210627100842635](https://i.loli.net/2021/06/27/ORhSC9Tz4Wkmt1I.png)

- 安装插件：在vscode中，可以选择离线插件进行安装，步骤如下：

  快捷键`ctrl+shift+p`呼出控制面板-->输入vsix，选择install from vsix-->选择下载好的插件离线包进行安装

  ![image-20210627101504102](https://i.loli.net/2021/06/27/K9nmWfAiREC7S4U.png)

  

  







# 二：配置C开发环境

> C++开发环境包括：编辑器Editor，编译器Compiler和Debuger。编辑器就是VSCode；在Linux环境下编译器可以使用g++和gcc，debuger可以使用GDB；在Windows环境下编译器和编辑器可以使用mingw64

## （1）安装Compiler和Debuger

1. Linux环境下，搭建C开发环境很简单，直接使用如下命令即可安装编译器和gdb

   ```bash
   # 安装编译器
   sudo apt install gcc g++
   # 安装gdb
   sudo apt install gdb
   ```

2. Windows环境下，需要下载mingw64，并且配置环境变量

   百度mingw可以进入到mingw官网，可以下载安装包或者离线包进行安装（使用安装包的方式安装mingw64可能会由于网络问题，导致安装失败，所以推荐下载离线包进行安装）

   点击此链接：https://sourceforge.net/projects/mingw-w64/files/，进入下图1后将页面往下滑到图2区域，点击所需离线包名称（参照方法一第三步标注），然后就会弹出图3所示对话框，保存下载即可（下载x64-32_win32-sjlj版本的）。离线包大约50MB（解压后500MB左右）

   ![mingw64_01](https://i.loli.net/2021/07/06/YpszqWE2NbUkJaX.jpg)

   ![mingw64_02](https://i.loli.net/2021/07/06/zy3XvKinIoh1rOL.jpg)

   下载完成后，解压到本地，将其bin文件夹所在的路径，配置到计算机环境变量Path中：

   ![image-20210706225545998](https://i.loli.net/2021/07/06/spve9QnxUCj7XAV.png)

   **验证是否安装成功**：打开CMD命令行，输入`g++ -v`，如果能出现相应的g++版本信息，即说明安装成功



## （2）在VSCode中配置luanch和tasks文件

经过上述的步骤之后，我们已经在电脑上配置好了C/C++的编译和调试环境了。接下来就可以配置VSCode，在VScode中实现代码的**编译**和**调试**。

1. 在VScode中添加一个C++文件，输入一段简单的C++代码：

   ![image-20210706230133059](https://i.loli.net/2021/07/06/g1TXS4ZNjJEzPKH.png)

   此时VSCode会识别到这是一个C++文件，会提示我们安装C++相应的拓展插件，我们点击安装即可，安装完成之后，会在插件列表里看到对应的插件信息。

2. 调试程序：

   点击左边的调试图标，选择`create a launch.json file`，此时vscode会创建一个.vscode文件夹，并且在改文件夹下创建一个launch.json文件。这个文件就会告诉VSCode去哪里找可以行程序，并且如何进行调试。

   ![image-20210706230609215](https://i.loli.net/2021/07/06/ITckeJf9xWCUXAa.png)

   点击`C++(GDB/LLDB)`之后，会让我们选择如何生成tasks.json文件(这个文件告诉VSCode如何将.cpp文件，编译成可执行文件，供launch.json文件调试时使用)。此时我们选择第一个：`g++.exe生成和调试活动文件`，指通过g++来编译我们的.cpp源文件。

   ![image-20210706231015796](https://i.loli.net/2021/07/06/w8jroAZUnIMReq6.png)

   此时我们已经拥有了tasks.json文件来编译程序和launch.json文件来执行、调试程序了。点击调试栏的绿色开始符号，就可以开始运行，并且打断点调试程序了。

   ![image-20210706231315557](https://i.loli.net/2021/07/06/fY72LsjKeGMA3U9.png)

