---
title: 从0开始，手把手教你学会MySQL 5.7安装
date: 2021-07-09 07:47:10
tags: MySQL
---

> 新手从0开始，手把手教你学会安装MySQL 5.7 到Windows10，只要能看懂中文，就能安装成功。

![image-20210709080219153](https://i.loli.net/2021/07/09/GvQxoNTuRBLIyez.png)

<!--more-->

# 1 下载MySQL 5.7解压文件，并且解压到电脑

MySQL可以下载在线安装程序，也可以下载离线安装包进行安装，相比之下，我认为直接下载离线安装包到本地会更加的方便，对于不能科学上网的人来说，速度也会更快一点（因为采用在线安装的方式，如果不能科学上网，下载MySQL对应的文件会十分的慢，甚至不能下载）。

## 1.1 获取MySQL5.7安装包

可以选择百度MySQL，进入到MySQL官网进行下载，也可以访问这个[百度网盘链接](https://pan.baidu.com/s/1w89e1j4P0jN0bBsJa1kggg)(提取码是：x8v4)进行下载。下载到本地之后，会获得一个MySQL的压缩包，选择将其解压到本机任意目录即可。

![image-20210709071747083](https://i.loli.net/2021/07/09/7NvwJC8eA6Fcz9m.png)

## 1.2 配置环境变量

本步需要将MySQL的bin文件的绝对路径，配置到Windows10的Path中去：

![image-20210709072440047](https://i.loli.net/2021/07/09/mY8eMPS27DX64Hv.png)

![image-20210709072638230](https://i.loli.net/2021/07/09/Aa8kI9CQdUPbqVz.png)



# 2 配置mysql

1. 使用管理员身份打开CMD

   ![image-20210709072814764](https://i.loli.net/2021/07/09/BzoWdGjHQ24VPhp.png)

2. 编辑`my.ini`配置文件

   如果在MySQL的安装目录下，没有此文件，需要自己手动创建。**注意：后缀名需要是ini而不是txt**

   ```ini
   [mysqld]
   basedir=D:\Programming\mysql_5.7
   datadir=D:\Programming\mysql_5.7\data\
   port=3306
   skip-grant-tables
   ```

   ![image-20210709073545221](https://i.loli.net/2021/07/09/NsgoDekaqt7zRVK.png)

3. 进入到MySQL bin目录所在文件夹下：

   ```bash
   cd /d D:\Programming\mysql_5.7\bin
   ```

   ![image-20210709073005532](https://i.loli.net/2021/07/09/8B3IkMhPzlVjs12.png)

4. 注册MySQL service

   ```bash
   mysqld -install
   ```

   ![image-20210708234552361](https://i.loli.net/2021/07/09/ly4cMfWP5hrB2XJ.png)

5. 初始化数据文件

   ```bash
   mysqld --initialize-insecure --user=mysql
   ```

   ![image-20210708234612431](https://i.loli.net/2021/07/09/uyQLIiMe85Y36qb.png)

6. 启动MySQL数据库

   ```bash
   net start mysql
   ```

   ![image-20210708234640646](https://i.loli.net/2021/07/09/cf6PdJ3Cb7lMD5N.png)

7. 进入MySQL

   第一次进入到MySQL，由于我们在配置文件中，最后一行配置了`skip-grant-tables`.所以此时进入MySQL可以无密码进入。

   ```bash
   mysql –u root –p
   ```

   ![image-20210708234756231](https://i.loli.net/2021/07/09/aAkL1GOf4ejSMwy.png)

8. 更改root密码

   其中**password('123456')**可以设置成自己的密码。

   ```bash
   update mysql.user set authentication_string=password('123456') where user='root' and Host = 'localhost';
   ```

   ![image-20210708234814899](https://i.loli.net/2021/07/09/QiSEnsfcp7hD3dM.png)

9. 刷新权限

   ```bash
   flush privileges;
   ```

   ![image-20210708234840671](https://i.loli.net/2021/07/09/lWQX27hTAG39CNa.png)

10. 退出MySQL

    ```bash、
    exit;
    ```

    ![image-20210708234856950](https://i.loli.net/2021/07/09/HlOPhMTNFSGoZLq.png)

11. 注释掉MySQL配置文件my.ini最后一行的`skip-grant-tables`

    ![image-20210708234930160](https://i.loli.net/2021/07/09/SDrz4yst8LWkboJ.png)

12. 重启MySQL服务，输入配置好的密码进入到MySQL

    需要强调的是，-p后面直接输入自己的密码，不要加空格（因为空格也算一个字符，如果加了空格，肯定就和自己设置的真正的密码不能匹配了）

    ```bash
    net stop mysql
    net start mysql
    mysql -u root -p123456
    ```

    ![image-20210708235006013](https://i.loli.net/2021/07/09/GvaESJ4xspTziIh.png)



到此，MySQL 5.7所有的安装步骤就结束了，感谢大家的阅读。























