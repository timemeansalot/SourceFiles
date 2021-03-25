---
title: wsl_config
date: 2021-03-23 13:34:43
tags: wsl
---



Windows利用WSL配置Linux开发环境的详细教程

[[_TOC_]]

<!--more-->

# 本地安装WSL

在Windows应用商店直接可以安装wsl

配置本地的WSL环境：https://172.16.2.224/mprojects/mnm/-/blob/master/tb/mnm_sdk_test.md

```bash
sudo apt update
sudo apt install -y  gcc make  build-essential python2 libtool flex bison
cd /usr/bin/
sudo ln -s python2 python

cd ~
echo 'export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/local/lib:/lib' >> .bashrc
source .bashrc

sudo apt install gcc-10 g++-10 -y
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 40
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 40
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 50
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-10 50
```



# 配置google test

git clone https://gitee.com/milley/googletest.git
cd googletest
mkdir build
cd build
cmake ..
make
make install

# 配置SSH

建议重装之前先备份.ssh，这样重装了就不用更新服务器上的Key了

install PcapPlusPlus

参考：[链接](https://172.16.2.224/mprojects/mnm/-/tree/master/av_test/pkt_gen)





221 passwod

`ao1ncc/PEe8jYLlumDLZviB+sVPB9WFe8csW6lniXQ`







WSL mount 磁盘

```bash
在windows 下移动硬盘位 z

在ubuntu 下输入命令：
sudo mkdir /mnt/z
(此命令为在 Windows 下新建一个 Z盘,访问 windows 下的文件 cd /mnt/z)

挂载盘符 z
sudo mount -t drvfs z: /mnt/z

最后，输入 mnt/Z 和windows 下是一模一样的

```





# 安装PcapPlusPlus



PcapPlusPlus is available on Windows,  Linux, MacOS and FreeBSD (see more details [here](https://pcapplusplus.github.io/docs/install)). This file will show you how to set up PcapPlusPlus on WSL. 

```bash
 sudo apt-get install libpcap-dev 
```

```shell
git clone https://gitee.com/mirrors/PcapPlusPlus.git
```

``` bash
cd PcapPlusPlus # go to PcapPlusPlus folder that we clone
./configure-linux.sh
```

To build the libraries only (without the unit-tests and examples) run `make libs` instead of `make all`

After compilation you can find the libraries, examples, header files and helpful makefiles under the `Dist` directory

```shell
make libs
```

After build is complete you can run the installation script which will copy the library and header files to the installation directory:

The default installation directory is `/usr/local` which means the header files will be copied to `/usr/local/include/pcapplusplus` and the library files will be copied to `/usr/local/lib`.

```bash
sudo make install
```



Example src codes are under `av_test/pkt_gen` folder. Below are the folder structure:

- `example`: Demonstrate how to craft packet usinfg PcapPlusPlus and convert packet into core_ipm_ipp_if instance.
- `ptk_gen.h`: Contains all the needed PcapPlusPlus header files, so we just need to include ptk_gen.h in example.cpp file.
- `pkt_gen.cpp`: Implement ConvertToIppIntf function which can convert Packet instance into core_ipm_ipp_if instance.

```shell
jfu@JieFu:/mnt/d/codes/mersenne/mnm/av_test/pkt_gen$ tree
.
├── Makefile
├── example.cpp
├── pkt_gen.cpp
└── pkt_gen.h

```



In order to make vscode identify PcapPlusPlus header files so that vscode can provide Intelligent Code Completion function, you can get the full instructions [here](https://www.cnblogs.com/hubery/p/7375215.html). The basic operation steps are as follows:

- open vscode and redirect to mnm folder

- `ctrl+shift+p`and type in`Edit Configurations(JSON)`then press return button: this will create a folder named `.vscde`and a json file called `c_cpp_properties.json`

- replace all the json file with:

  ```json
  {
      "configurations": [
          {
              "name": "Linux",
              "includePath": [
                  "${workspaceFolder}/**",
                  "/usr/local/include/pcapplusplus/**"
              ],
              "defines": [],
              "compilerPath": "/usr/bin/gcc",
              "cStandard": "gnu17",
              "cppStandard": "gnu++14",
              "intelliSenseMode": "linux-gcc-x64"
          }
      ],
      "version": 4
  }
  ```

  As you can see, we just add `"/usr/local/include/pcapplusplus/**"`to includPath and that's all.

If you want to learn more about how to use PcapPlusPlus, please click this [link](https://pcapplusplus.github.io/docs/tutorials). It gives 5 detailed examples which demonstrate PcapPlusPlus main features.