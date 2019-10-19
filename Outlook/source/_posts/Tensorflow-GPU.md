---
title: Tensorflow-GPU
date: 2019-06-13 20:45:52
tags:
	-: tensorflow
---



# <center> <font color=#A52A2A size=7> Tensorflow从源码编译安装tensorflow-gpu版本</font></center>



教你安装NVIDIA驱动，安装cuda，cudnn，bazel

教你通过使用bazel编译tensorflow源文件安装tensorflow-gpu版本

<center>[![VouAAI.md.png](https://s2.ax1x.com/2019/06/15/VouAAI.md.png)](https://imgchr.com/i/VouAAI)</center>

<!--more-->



# <center> <font color=#A52A2A size=7> tensorflow</font></center>

tensorflow-gpu的安装主要分为4步：

- 更新nvidia驱动
- 安装Cuda和cuDNN
- 安装Bazel
- 编译安装tensorflow-gpu版本



## <font size=6 color=#FF7F50>Step1：更新驱动</font>

更新驱动有两种方式，一种是在终端通过网络更新，一种是手动更新

### <font size=5 color=#00FFFF>方法一：手动更新</font>

首先我们要下载418版本的NVIDIA驱动

#### <font color=#008000 size=4>1. 禁止Nouveau驱动，避免开机卡在logo处</font>

```
sudo vim /boot/grub/grub.cfg 
在文本中搜索quiet slash 然后添加acpi_osi=linux nomodeset，保存文本即可。
#或者可以
sudo vim sudo gedit /etc/modprobe.d/blacklist.conf
添加：
blacklist nouveau
```

#### <font color=#008000 size=4>2. 卸载低版本的nvidia驱动</font>

```
sudo apt-get purge nvidia*
sudo apt-get --purge remove xserver-xorg-video-nouveau
```

#### <font color=#008000 size=4>3. 关闭lightdm</font>

重启电脑，按ctrl+alt+F2进入x-server
输入用户名和密码

```shell
sudo service lightdm stop
如果提示unit lightdm.service not loaded
则先安装LightDm： sudo apt install lightdm
安装完毕后跳出一个界面，选择lightdm，再sudo service lightdm stop
```

#### <font color=#008000 size=4>4. 执行安装程序</font>

```
cd Downloads
sudo chmod a+x NVIDIA....(自行下载的驱动名)  
sudo ./NVIDIA.....(自行下载的驱动名)
```

#### <font color=#008000 size=4>5. 重启lightdm</font>

```
sudo service lightdm start

```

至此，驱动更新完成，可在终端验证

```
nvidia-smi
```



### <font size=5 color=#00FFFF>方法二：网络安装</font>

前两步和手动安装相同

#### <font color=#008000 size=4>3.添加ppa源</font>

```
sudo add-apt-repository ppa:graphics-drivers
sudo apt-get update
```

#### <font color=#008000 size=4>4.查看可用驱动</font>

```
ubuntu-drivers devices
```

会显示很多驱动，其中还有一个recommed的驱动,我们使用418版本的

#### <font color=#008000 size=4>5.安装驱动</font>

```
sudo apt install nvidia-418
```

至此，驱动更新完成，可在终端验证

```
nvidia-smi
```



## <font size=6 color=#FF7F50>Step2 ：安装CUDA和cuDNN</font></center>



CUDA是NVIDIA开发的用于科学技术的工具，cuDNN是配合CUDA使用的。

在安装他们之前，我们**首先要根据我们需要的tensorflow版本来确定我们需要的cuda和cuDNN版本**,不然就会出错。因为我们使用tensorflow1.13，所以我们需要Cuda10.0和cuDNN7.6.0

### <font size=5 color=#00FFFF>一：安装CUDA10.0</font>

#### <font color=#008000 size=4>1.下载</font>

去nvidia官网[地址](<https://developer.nvidia.com/cuda-toolkit-archive>)下载10.0版本的cuda,下载.sh文件。如图所示

<center>[![Vonz9K.md.png](https://s2.ax1x.com/2019/06/15/Vonz9K.md.png)](https://imgchr.com/i/Vonz9K)</center>

#### <font color=#008000 size=4>２．安装</font>

```
sudo sh cuda_10.0.130_410.48_linux.run
```

不要选择为显卡安装加速驱动，因为我们已经在第一步时安装了驱动了

在终端下检验,会输出相应信息

```
nvcc --version
```



### <font size=5 color=#00FFFF>二：安装cuDNN</font>

#### <font color=#008000 size=4>1.下载cuDNN</font>

下载比较麻烦，要注册账号，不过下载还是很简单的，下载linux版本都就可以

#### <font color=#008000 size=4>2.使用cuDNN</font>

```
sudo cp cuda/include/cudnn.h /usr/local/cuda/include/
sudo cp cuda/lib64/libcudnn* /usr/local/cuda/lib64/
sudo chmod a+r /usr/local/cuda/include/cudnn.h
sudo chmod a+r /usr/local/cuda/lib64/libcudnn*
```

在终端下检验输出相应信息

```
cat /usr/local/cuda/include/cudnn.h | grep CUDNN_MAJOR -A 2
```

或者也可以直接下载ubuntu版本的runtime deb包安装

## <font size=6 color=#FF7F50>Step 3:安装bazel</font>

bazel是谷歌推出的tensorflow变异工具，通过它，我们变异tensorflow，他的安装可以参考[官方教程](<https://docs.bazel.build/versions/master/install-ubuntu.html>)

### <font size=5 color=#00FFFF>1.安装依赖</font>

```
sudo apt-get install pkg-config zip g++ zlib1g-dev unzip python
```

### <font size=5 color=#00FFFF>2.下载bazel</font>

Next, download the Bazel binary installer named `bazel-<version>-installer-linux-x86_64.sh` from the [Bazel releases page on GitHub](https://github.com/bazelbuild/bazel/releases).

### <font size=5 color=#00FFFF>3.运行安装程序</font>

```
chmod +x bazel-<version>-installer-linux-x86_64.sh
./bazel-<version>-installer-linux-x86_64.sh --user
```

The `--user` flag installs Bazel to the `$HOME/bin` directory on your system and sets the `.bazelrc` path to `$HOME/.bazelrc`. Use the `--help` command to see additional installation option

### <font size=5 color=#00FFFF>4.配置环境变量</font>

If you ran the Bazel installer with the `--user` flag as above, the Bazel executable is installed in your `$HOME/bin` directory. It’s a good idea to add this directory to your default paths, as follows:

```
export PATH="$PATH:$HOME/bin"
```

You can also add this command to your `~/.bashrc` file.



## <font size=6 color=#FF7F50>Step 4：编译tensorflow-gpu版本</font>

具体编译过程可以参考[官方文档](<https://www.tensorflow.org/install/source>)

### <font size=5 color=#00FFFF>1. 安装依赖</font>

```
sudo apt install python-dev python-pip  # or python3-dev python3-pip
pip install -U --user pip six numpy wheel setuptools mock future>=0.17.1
pip install -U --user keras_applications==1.0.6 --no-deps
pip install -U --user keras_preprocessing==1.0.5 --no-deps
```

Install the TensorFlow *pip* package dependencies (if using a virtual environment, omit the `--user` argument):

### <font size=5 color=#00FFFF>2.克隆tensoflow库</font>

```
git clone https://github.com/tensorflow/tensorflow.git
cd tensorflow
```

The repo defaults to the `master` development branch. You can also checkout a [release branch](https://github.com/tensorflow/tensorflow/releases) to build:

```bsh
git checkout branch_name  # r1.9, r1.10, etc.
```

### <font size=5 color=#00FFFF>3.Configure</font>

```
./configure
```

### <font size=5 color=#00FFFF>4.编译</font>

- CPU-only

Use `bazel` to make the TensorFlow package builder with CPU-only support:

```
bazel build --config=opt //tensorflow/tools/pip_package:build_pip_package
```



- GPU support

To make the TensorFlow package builder with GPU support:

```
bazel build --config=opt --config=cuda //tensorflow/tools/pip_package:build_pip_package
```

### <font size=5 color=#00FFFF>5.构建tensorflow安装包</font>

```
./bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg
```

### <font size=5 color=#00FFFF>6.安装tensorflow-gpu</font>

```bsh
pip install /tmp/tensorflow_pkg/tensorflow-version-tags.whl
```

安装完毕之后，可以在Python环境中验证

```
import tensorflow as tf 
hello=tf.constant('hello world from tensorflow')
sess=tf.Session()
sess.run(hello)
```

如果能够输出**hello world from tensorflow**即安装成功