---
title: hexo搭建博客
date: 2021-03-16 12:29:38
tags: hexo
---



[[_TOC_]]



利用hexo和gitee搭建自己的博客

<!--more-->

# picgo

smms图床：https://sm.ms/home/apitoken

使用picgo上传图片到smms图床：https://github.com/Molunerfinn/PicGo/releases

# nodejs & npm

> 不要选择高版本的nodejs，选择版本为12的，不然hexo d的时候会报错

**使用NVM安装和管理nodejs**：https://www.cnblogs.com/czql/articles/11064849.html。

**第一步：下载**

下载地址：https://github.com/coreybutler/nvm-windows/releases

**第二步：安装**

按照提示完成安装即可，安装完成后可以检测一下是否安装成功

在cmd命令行输入nvm,如果出现nvm版本号和一系列帮助指令，则说明nvm安装成功。

**第三步：修改settings.txt**

在你安装的目录下找到settings.txt文件，打开后加上 
node_mirror: https://npm.taobao.org/mirrors/node/ 
npm_mirror: https://npm.taobao.org/mirrors/npm/

这一步主要是将npm镜像改为淘宝的镜像，可以提高下载速度。

如果使用nvm，则不用手动安装nodejs了，可以直接利用nvm安装指定版本的nodejs
*Ubuntu 安装 nvm*

```bash
git clone https://gitee.com/abulo_hoo/nvm.git
cd nvm/
ls
git branch
 chmod 777 nvm.sh
cat nvm.sh
. nvm.sh
nvm --version
nvm ls-remote
export NVM_NODEJS_ORG_MIRROR=https://npm.taobao.org/mirrors/node # use ali repo
nvm install 12.22.1 # install nodejs 12
```


手动安装nodejs：https://www.cnblogs.com/qiangyuzhou/p/10836561.html

https://nodejs.org/en/

使用NVM安装和管理nodejshttps://www.cnblogs.com/czql/articles/11064849.html

# hexo

安装hexo（ubuntu下加上sudo，Windows下载CMD中输入命令，不用添加sudo）

```bash
npm config set registry http://registry.npm.taobao.org 
npm install -g hexo-cli 
npm install hexo-deployer-git
npm install --save hexo-blog-encrypt
npm install 

hexo new page_name # 添加文章页面
hexo s # 在本地调试页面
hexo d -g # 推送页面到GitHub
```

# Trouble Shot

## Can't use git clone on /mnt/d
```bash
error: chmod on /mnt/d/codes/SourceFiles/.git/config.lock failed: Operation not permitted
```
Follow [this link](https://askubuntu.com/questions/1115564/wsl-ubuntu-distro-how-to-solve-operation-not-permitted-on-cloning-repository) to fix this:
```bash
sudo umount /mnt/d
sudo mount -t drvfs D: /mnt/d -o metadata
```

## 每次打开Git都要ssh-agent bash

在 git 的安装目录的 bash.bashrc 文件，末尾添加：

```
#ssh-add 改为你电脑的秘钥名称
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/yes
ssh-add ~/.ssh/gtwm
```



## hexo发生error：spawn failed错误的解决方法

1. 删除`.deploy_git`文件夹;
2. 然后，依次执行：
   `hexo clean`
   `hexo g`
   `hexo d`