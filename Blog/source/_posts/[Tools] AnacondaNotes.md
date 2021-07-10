---

title: anaconda
date: 2021-07-09 23:22:39
tags: 
- Anaconda
- Tools
---

>  使用anaconda对Python环境和包进行管理

![image-20210709232438115](https://i.loli.net/2021/07/10/3j2ncJq6IsbKBUd.png)

<!--more-->



# 1 配置清华源

参考[链接](https://mirror.tuna.tsinghua.edu.cn/help/anaconda/).

1. 在用户目录下生成`.condarc`文件

   ```bash
   conda config --set show_channel_urls yes
   ```

2. 替换condarc文件内容为如下：

   ```ini
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
   ```

3. 清除缓存

   ```bash
   conda clean -i
   ```

4. 测试：创建一个叫做numpy_env的环境，该环境中包含numpy包

   ```bash
   conda create -n numpy_env numpy
   ```

   

# 2 使用conda管理环境和包

1. conda 版本

   ```bash
   conda --version
   ```

2. 更新conda

   ```bash
   conda update conda
   ```

3. 环境管理

   ```bash
   conda create --name <env_name> <packet_name>
   ```

   - packet_name：可以在后面通过等号=指定包的版本号，如

     ```bash
     conda create --name python37 python=3.7
     ```

   - 创建的环境会被保存在``anaconda3/env`目录下

   - 切换环境

     ```bash
     activate <env_name> # 进入某环境
     deactivate # 退出某环境
     ```

   - 显示所有环境

     ```bash
     conda info --envs # 或者
     conda info -e # 或者
     conda env list
     ```

   - 复制环境

     ```bash
     conda create --name <new_env> --clone <old_env>
     ```

   - 删除环境

     ```bash
     conda remove --name <env_name> --all
     ```

4. 包管理

   - 精确查找

     ```bash
     conda search --fule-name <packet_name>
     ```

   - 模糊查找

     ```bash
     conda search <packet_name>
     ```

   - 获取当前环境下，所有安装的包

     ```bash
     conda list
     ```

   - 安装包到指定环境

     ```bash
     conda install --name <env_name> <packet_name>
     ```

   - 从特定的channel安装包：有些时候，默认的channel下有可能没有我们想要的包，我们需要从特定的channel安装包

     ```bash
     conda install -c <channel_name> <packet_name>
     ```

   - 在当前环境安装包

     ```bash
     conda install <packet_name>
     ```

   - 卸载指定环境中的包

     ```bash
     conda remove --name <env_name> <packet_name>
     ```

   - 卸载当前环境中的包

     ```bash
     conda remove <packet_name>
     ```

   - 更新所有包

     ```bash
     conda update --all # 或者conda upgrade --all
     ```

   - 更新指定的包

     ```bash
     conda update <packet_name> # 或者conda upgrade <packet_name>
     ```

     

# 3  下载一些当前channel不存在的包

1. 登录[anaconda官网](https://anaconda.org/)

2. 在搜索栏搜索需要的包，回车即可

   ![image-20210710093208444](https://i.loli.net/2021/07/10/HZC8flWsLYgNP1t.png)

3. 一般会显示多个搜索结果，我们选择下载数最多的那个

   ![image-20210710093357373](https://i.loli.net/2021/07/10/VKdGfSJUoIAwD4Y.png)

4. 进入到对应的页面后，会提供我们下载的指令，选择一条，在命令行中执行即可，在执行命令的时候，注意切换到自己想要安装的对应的环境中去

   ```bash
   conda activate <env_name>
   ```

   ![image-20210710093528391](https://i.loli.net/2021/07/10/Q3Hbpa2hrTqkY1i.png)

