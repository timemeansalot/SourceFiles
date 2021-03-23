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

**使用NVM安装和管理nodejs**：https://www.cnblogs.com/czql/articles/11064849.html。如果使用nvm，则不用手动安装nodejs了，可以直接利用nvm安装指定版本的nodejs

手动安装nodejs：https://www.cnblogs.com/qiangyuzhou/p/10836561.html

https://nodejs.org/en/

使用NVM安装和管理nodejshttps://www.cnblogs.com/czql/articles/11064849.html

# hexo

安装hexo（ubuntu下加上sudo，Windows下载CMD中输入命令，不用添加sudo）

```bash
sudo npm config set registry http://registry.npm.taobao.org 

sudo npm install -g hexo-cli 

sudo npm install 

sudo npm install hexo-deployer-git
sudo npm install --save hexo-blog-encrypt

hexo new page_name # 添加文章页面
hexo s # 在本地调试页面
hexo d -g # 推送页面到GitHub
```

