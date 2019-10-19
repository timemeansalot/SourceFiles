---
title: Hexo搭建博客手把手教程
date: 2019-01-13 20:59:04
tags: 
    - Hexo
    - Blog
---

# <center> <font color=#A52A2A size=7>使用hexo搭建博客详细教程</font></center>



<center>[![VoMXAs.md.png](https://s2.ax1x.com/2019/06/15/VoMXAs.md.png)](https://imgchr.com/i/VoMXAs)</center>

<!--more-->



# <font color="#EE0000">创建hexo</font>
1. <font color="#4EEE94">安装Git、NodeJS、npm</font>
2. <font color="#4EEE94">安装hexo</font>
创建一个文件夹如**blog**，当做是博客文件夹。用命令：
```
npm install hexo -g
```
   安装hexo
3. <font color="#4EEE94">初始化hexo</font>
```
hexo init
```
4. <font color="#4EEE94">配置hexo组件</font>
```
npm install
```
5. <font color="#4EEE94">安装deployer扩展</font>
```
npm install hexo-deployer-git --save 
```
6. <font color="#4EEE94">hexo 命令</font>
 1) hexo cl:清空临时文件
 2) hexo s -g:本地查看博客效果
 3) hexo d -g:推送博客到github仓库

# <font color="#EE0000">关联hexo和github仓库</font>
1. <font color="#4EEE94">配置密匙</font>
```
cd ~/.ssh
ssh-keygen -t rsa -C '你的github账号'
```
   添加密匙到你的github中
2. <font color="#4EEE94">配置hexo的_config文件</font>
```
deploy:
type: git
repo: 你的github仓库链接
branch: master
```
3. <font color="#4EEE94">配置本机的git环境</font>
```
git config --global user.name 'github名字'
git config --global user.email 'github账号'
```
   然后可以用
```
git config --global --list
```
   查看配置信息

# <font color="#EE0000">配置NEXT主题</font>
```
git clone https://github.com/iissnan/hexo-theme-next themes/next
```
 1) 在网站配置文件中，选择主题为next
 2) 在next的配置文件中,配置菜单，添加：
  * tags
  * about

# <font color="#EE0000">HEXO补充</font>
1. <font color="#4EEE94">[文章置顶](https://donlex.cn/archives/caeb67e2.html)</font>
2. <font color="#4EEE94">[Hexo美化](https://www.jianshu.com/p/9f0e90cc32c2)</font>
3. <font color="#4EEE94">字数统计和估计阅读时间</font>
```
npm install hexo-wordcount --save
```
   在配置文件中配置：
   ```
   post_wordcount:
   item_text: true
   wordcount: true
   min2read: true
   totalcount: false
   separated_meta: true
   ```
4. <font color="#4EEE94">leancloud阅读次数统计</font>
* 在[leancloud](https://tab.leancloud.cn/login.html#/signin)注册账号
* 创建应用并且添加一个class:**Counter**
* 配置主题文件：
```
  leancloud_visitors:
  enable: true
  app_id: 你的app_id
  app_key: 你的app_key
```
5. <font color="#4EEE94">Hexo加密</font>
1) 更改Hexo根目录下文件夹：package.json
添加"hexo-blog-encrypt": "2.0.* "
![](https://s2.ax1x.com/2019/01/13/FvxzS1.png)
2) 更改Hexo根目下的文件夹： _ config.yml
在文件末尾添加
encrypt:
    enable: true
    default_abstract: 密码是你的电脑开机密码，不知道密码的狗比，你看锤子看
    default_message: 在这儿输入你的密码哦.
其中default_abstract是主界面的提示信息
    default_message是密码输入框的提示信息
![](https://s2.ax1x.com/2019/01/13/Fvzpy6.png)
3) 更改：密码错误时的提示信息
打开文件夹node_modules->hexo-blog-encrypt->index.js
更改：hexo.config.encrypt.default_decryption_error = 'xxx'，其中xxx为你希望的提示信息
![](https://s2.ax1x.com/2019/01/13/FvzAFH.png)
4) 在想要加密的博客头部添加密码
在想要加密的博客的头部添加：password: xxx,其中xxx是您设计的密码
![](https://s2.ax1x.com/2019/01/13/FvzEYd.png)


# <font color="#EE0000">SSH配置</font>
1. <font color="#4EEE94">在本地用命令生成ssh key,名字要自己取</font>
```
ssh-keygen -t rsa -C 'email'
```
2. <font color="#4EEE94">添加到ssh库</font>
```
ssh-add rsa
ssh-add -l
```
3. <font color="#4EEE94">配置ssh的config文件，例如：</font>
```
Host test-github
	HostName github.com
	User git
	IdentityFile ~/.ssh/id_rsa_test_github
```
其中 Host的IdentityFile最重要，在克隆的时候，用Host来取代github.com
4. <font color="#4EEE94">添加公匙到github的仓库的key中</font>


> **参考文献**

 - Hexo美化：<https://www.jianshu.com/p/9f0e90cc32c2>
 - SSH详细教程：<http://shinancao.github.io/2016/12/18/Programming-Git-1/>
 - 更改颜色： <https://blog.csdn.net/weixin_40837922/article/details/88047241>
 - git的submodule： <https://blog.csdn.net/xuanwolanxue/article/details/80609986>
