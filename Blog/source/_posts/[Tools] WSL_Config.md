---
title: wsl_config
date: 2021-03-23 13:34:43
tags: wsl
---



Windows利用WSL配置Linux开发环境的详细教程

[[_TOC_]]

<!--more-->



# Install Ubuntu to Windows

1. Open WSL function in Windows

   Follow this [Guide](https://docs.microsoft.com/zh-cn/windows/wsl/install-win10) provided by Microsoft to enable WSL2 function in Windows. Do the following commands in `Power Shell` with administrator authority. 

   - enable wsl function

     ```shell
     dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
     ```

   - enable virtualization function

     ```shell
     dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
     ```

     `Reboot Windows`

   - set wsl default version to 2

     Download WSL kernel update packet by this [link](https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi), run the update packet.

     ```shell
     wsl --set-version Ubuntu 2
     wsl --set-default-version 2
     ```

   ```
     
     
   ```

2. Download Ubuntu-20.04 zip file

   Go to [Link](https://docs.microsoft.com/en-us/windows/wsl/install-manual) to download Ubuntu20.04

3. Install Ubuntu using LxRunOffline

   Go to [Github Repo](https://github.com/DDoSolitary/LxRunOffline/releases) to donwload **[LxRunOffline-v3.5.0-msvc.zip](https://github.com/DDoSolitary/LxRunOffline/releases/download/v3.5.0/LxRunOffline-v3.5.0-msvc.zip)**. Extract the zip file and add folder route to PATH in Windows.

   ```shell
   # install ubuntu
   ## LxRunOffline i -n <wsl_name> -d <install location> -f <source_folder/install.tar.gz>   for examle:
   LxRunOffline.exe i -n Ubuntu -d "D:\Programming\WSL\Ubuntu" -f "D:\Programming\extract\install.tar.gz"
   
   # set default wsl version to Ubuntu
   LxRunOffline.exe sd -n Ubuntu
   # Create Link
   LxRunOffline.exe s -n Ubuntu -f Ubuntu-20.04.lnk
   ```

   

# Modify Ubuntu

Run all the commands in `Ubuntu` by type `wsl` in Power Shell to launch Ubuntu.

1. Change repository source to Tsinghua University

   ```shell
   vim /etc/apt/sources.list
   ```

   change the default text to:

   ```
   # 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
   deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal main restricted universe multiverse
   # deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal main restricted universe multiverse
   deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-updates main restricted universe multiverse
   # deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-updates main restricted universe multiverse
   deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-backports main restricted universe multiverse
   # deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-backports main restricted universe multiverse
   deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-security main restricted universe multiverse
   # deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-security main restricted universe multiverse
   
   # 预发布软件源，不建议启用
   # deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-proposed main restricted universe multiverse
   # deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-proposed main restricted universe multiverse
   ```

2. Add user

   ```bash
   # add user and set password
   useradd -m jfu -d /home/jfu -s /bin/bash 
   passwd jfu
   
   # add user to suders group
   chmod +w /etc/sudoers
   vim /etc/sudoers
   
   root　ALL=(ALL:ALL) ALL
   jfu ALL=(ALL:ALL) ALL # add this line
   
   chmod -w /etc/sudoers
   ```

3. Download and install MobaXterm

   Go to this [Link](https://mobaxterm.mobatek.net/download-home-edition.html) to download MobaXterm, it is a very powerful and free shell application.

4. Config ssh and git

   ```bash
   mkdir .ssh
   cd .ssh
   ssh-keygen -t rsa
   # copy the public key to your repo ssh
   ```

   

# Config WSL environment

在Windows应用商店直接可以安装wsl

配置本地的WSL环境：https://172.16.2.224/mprojects/mnm/-/blob/master/tb/mnm_sdk_test.md

```bash
sudo apt update
sudo apt install -y  gcc make  cmake build-essential python2 libtool flex bison
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
sudo make install

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