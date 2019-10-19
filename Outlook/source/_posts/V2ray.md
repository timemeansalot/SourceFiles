---
title: v2ray全面使用保姆级教程
date: 2019-04-05 11:17:52
tags:
    - v2ray
---

# <center> <font color=#A52A2A size=7>V2ray详细教程</font></center>



购买服务器配置v2ray并且在linux配置使用。
使用docker容器。
如果要看怎样使用，请直接往下翻，找到对应的版本

<center>[![VoK6ds.md.png](https://s2.ax1x.com/2019/06/15/VoK6ds.md.png)](https://imgchr.com/i/VoK6ds)</center>

<!--more-->



# <center> <font color=#A52A2A size=7> 服务器部署V2ray </font></center>



## <font size=6 color=#FF7F50>Step 1:链接远程服务器</font>

1. digital ocean

   ```
   ssh root@serverIP
   password
   ```
   
2. gcp

   用gcp自带的ssh登录

## <font size=6 color=#FF7F50>Step 2:修改时区</font>

```
date -R
tzselect
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
date -R
```

## <font size=6 color=#FF7F50>Step 3: 使用BBR加速</font>

```
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p
lsmod | grep bbr
```

## <font size=6 color=#FF7F50>Step 4:部署v2ray服务</font>

部署v2ray有两种方式，一种是使用docker部署v2ray，另一种是使用直接使用v2ray

<font size=5 color=#00FFFF>- 方法一：使用docker</font>

使用docker直接安装，有很多好处，毕竟docker是将来的大势所趋。可以在提供相同服务质量的同时，占用很少很少的硬件资源

<font color=#008000 size=4>第一步：安装docker</font>

安装docker其实很简单，具体参考[docker的官方文档](<https://docs.docker.com/install/linux/docker-ce/ubuntu/>)就行。

<font color=#008000 size=4>第二步：部署v2ray/offcial</font>

**v2ray/official**是v2ray在docker中的一个官方镜像，所以直接拉取它就行。

```
docker pull v2ray/official
mkdir /etc/v2ray
cd /etc/v2ray
vim config.json
```

复制下列代码到config.json，完成配置

```
{
  "inbounds": [{
    "port": 8888,
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "c97e81ac-b66e-49bc-8c13-66240351f636",
          "level": 1,
          "alterId": 64
        }
      ]
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": ["geoip:private"],
        "outboundTag": "blocked"
      }
    ]
  }
}

```

启动docker运行v2ray镜像

```
docker run -d --name v2ray -v /etc/v2ray:/etc/v2ray -p 8888:8888 v2ray/official  v2ray -config=/etc/v2ray/config.json
docker ps
```

### <font size=5 color=#00FFFF>- 方法二：直接使用v2ray</font>

在服务端直接使用v2ray是最简单的部署v2ray方式。只需要下面几行代码即可

#### <font color=#008000 size=4>第一步：安装v2ray</font>

使用下面几行代码就可以安装v2ray到我们的服务器上了

```shell
apt-get update
apt-get install curl -y
bash < (curl -L -s https://install.direct/go.sh)
```

#### <font color=#008000 size=4>第二步：配置v2ray信息</font>

配置v2ray信息，是它可以利用我们买的服务器，变成一个VPN

利用下面的代码编辑v2ray配置文件

```shell
vim /etc/v2ray/config.json
```

然后复制下面的代码进去，就完成了对v2ray的配置

```shell
{
  "inbounds": [{
    "port": 22579, #开放服务器的22579接口
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "c97e81ac-b66e-49bc-8c13-66240351f636",
          "level": 1,
          "alterId": 64
        }
      ]
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": ["geoip:private"],
        "outboundTag": "blocked"
      }
    ]
  }
}
```

最后重启v2ray服务就行啦

```shell
systemctl restart v2ray.service
或者：
service v2ray restart
```



**至此，服务器端部署已经全部完成，接下来教教大家怎么在各平台下使用**



# <center> <font color=#A52A2A size=7>Linux电脑使用v2ray</font></center>

linux本地使用v2ray也有两种方法，一种是使用docker，一种是直接使用v2ray

## <font size=6 color=#FF7F50>方法一：使用docker</font>

首先要下载docker，方式可以参考[docker官方文档](<https://docs.docker.com/install/linux/docker-ce/ubuntu/>)

在docker中使用v2ray分为3步：

- 编辑配置文件
- 启动v2ray镜像
- 配置浏览器

### <font size=5 color=#00FFFF>第一步：编辑v2ray镜像配置文件</font>

```shell
mkdir v2ray #创建v2ray文件夹
cd v2ray #进入v2ray文件夹
vim config.json #编辑配置文件
```

复制下面的代码进入config.json文件

```shell
{
  "log": {
    "access": "",
    "error": "",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 10808,
      "listen": "127.0.0.1",
      "protocol": "socks",
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      },
      "settings": {
        "auth": "noauth",
        "udp": true,
        "ip": null,
        "clients": null
      },
      "streamSettings": null
    }
  ],
  "outbounds": [
    {
      "tag": "proxy",
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "68.183.237.179",
            "port": 22579,
            "users": [
              {
                "id": "c97e81ac-b66e-49bc-8c13-66240351f636",
                "alterId": 64,
                "email": "t@t.tt",
                "security": "auto"
              }
            ]
          }
        ],
        "servers": null,
        "response": null
      },
      "streamSettings": {
        "network": "tcp",
        "security": "",
        "tlsSettings": null,
        "tcpSettings": null,
        "kcpSettings": null,
        "wsSettings": null,
        "httpSettings": null,
        "quicSettings": null
      },
      "mux": {
        "enabled": true
      }
    },
    {
      "tag": "direct",
      "protocol": "freedom",
      "settings": {
        "vnext": null,
        "servers": null,
        "response": null
      },
      "streamSettings": null,
      "mux": null
    },
    {
      "tag": "block",
      "protocol": "blackhole",
      "settings": {
        "vnext": null,
        "servers": null,
        "response": {
          "type": "http"
        }
      },
      "streamSettings": null,
      "mux": null
    }
  ],
  "dns": null,
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": []
  }

```

### <font size=5 color=#00FFFF>第二步：在docker启动v2ray</font>

```shell
docker run --name v2ray -v $PWD:/ect/v2ray -p 10808:10808 v2ray/offcial
```

### <font size=5 color=#00FFFF>第三步：设置浏览器代理</font>

打开浏览器，配置socks5代理为127.0.0.1:10808即可，配置方法很简单，可以直接百度，或者参考[这篇文章](https://octopuspalm.top/2018/08/18/Linux%20%E7%B3%BB%E7%BB%9F%E4%B8%8Bv2ray%E5%AE%A2%E6%88%B7%E7%AB%AF%E4%BD%BF%E7%94%A8/)

## <font size=6 color=#FF7F50>方法二：直接使用v2ray</font>

直接使用v2ray分为4步：

- 下载v2ray
- 配置v2ray
- 重启v2ray
- 配置浏览器

### <font size=5 color=#00FFFF>第一步：下载v2ray</font>

由于我们的电脑现在是不可以翻墙的，所以我们无法用命令行直接安装v2ray

我们要分为两步

#### <font color=#008000 size=4>Step 1:下载linux安装包</font>

其实v2ray的所有发行版都放到了**github**上，我们可以直接去release中下载各个版本的v2ray压缩包，点击[连接](<https://github.com/v2ray/v2ray-core>),下载linux版本的即可

#### <font color=#008000 size=4>安装v2ray</font>

```shell
wget https://install.direct/go.sh
sudo bash go.sh --local ./v2ray-linux-64.zip 
```

使用上面两行命令，就安装好了v2ray

### <font size=5 color=#00FFFF>第二步：配置v2ray</font>

先打开配置文件：

```shell
sudo vim /etc/v2ray/config.json
```

粘贴下面的内容：

```shell
{
  "log": {
    "access": "",
    "error": "",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 10808,
      "listen": "127.0.0.1",
      "protocol": "socks",
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      },
      "settings": {
        "auth": "noauth",
        "udp": true,
        "ip": null,
        "clients": null
      },
      "streamSettings": null
    }
  ],
  "outbounds": [
    {
      "tag": "proxy",
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "68.183.237.179",
            "port": 22579,
            "users": [
              {
                "id": "c97e81ac-b66e-49bc-8c13-66240351f636",
                "alterId": 64,
                "email": "t@t.tt",
                "security": "auto"
              }
            ]
          }
        ],
        "servers": null,
        "response": null
      },
      "streamSettings": {
        "network": "tcp",
        "security": "",
        "tlsSettings": null,
        "tcpSettings": null,
        "kcpSettings": null,
        "wsSettings": null,
        "httpSettings": null,
        "quicSettings": null
      },
      "mux": {
        "enabled": true
      }
    },
    {
      "tag": "direct",
      "protocol": "freedom",
      "settings": {
        "vnext": null,
        "servers": null,
        "response": null
      },
      "streamSettings": null,
      "mux": null
    },
    {
      "tag": "block",
      "protocol": "blackhole",
      "settings": {
        "vnext": null,
        "servers": null,
        "response": {
          "type": "http"
        }
      },
      "streamSettings": null,
      "mux": null
    }
  ],
  "dns": null,
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": []
  }
}

```

其实这和在docker中使用v2ray是使用的同一份配置文件，这也体现了：docker能够提供同样的服务

### <font size=5 color=#00FFFF>第三步：重启v2ray</font>

```shell
sudo systemctl restart v2ray.service
或者
sudo service v2ray restart
```

### <font size=5 color=#00FFFF>第四步：配置浏览器</font>

很简单，可以直接百度，或者参考[这篇文章](https://octopuspalm.top/2018/08/18/Linux%20%E7%B3%BB%E7%BB%9F%E4%B8%8Bv2ray%E5%AE%A2%E6%88%B7%E7%AB%AF%E4%BD%BF%E7%94%A8/)

# <center> <font color=#A52A2A size=7>  Windows翻墙</font>

## <font size=6 color=#FF7F50>1. 下载软件</font>

打开百度网盘[链接](https://pan.baidu.com/s/1t7zTYnQIiobtp2Y64lS5bA),提取码为:**3aox**

## <font size=6 color=#FF7F50>1. 解压软件并安装</font>

解压我们从百度网盘下载的两个压缩包，得到两个文件夹:v2rayN和v2rayN-core。
把v2rayN文件夹中的**v2ray.exe**复制到v2rayN-core文件夹中

## <font size=6 color=#FF7F50>3. 软件使用</font>

1. 在v2rayN-core文件夹中点击v2rayN.exe文件运行。
2. 连接到服务器
 1) 复制下面的代码
 ```
 vmess://eyJhZGQiOiI2OC4xODMuMjM3LjE3OSIsImFpZCI6IjY0IiwiaG9zdCI6IiIsImlkIjoiYzk3ZTgxYWMtYjY2ZS00OWJjLThjMTMtNjYyNDAzNTFmNjM2IiwibmV0IjoidGNwIiwicGF0aCI6IiIsInBvcnQiOiIyMjU3OSIsInBzIjoibWUiLCJ0bHMiOiIiLCJ0eXBlIjoibm9uZSIsInYiOiIyIn0=
 ```
​      2) 在软件中按如下顺序添加即可
 ![AtxJVH.png](https://s2.ax1x.com/2019/03/25/AtxJVH.png)

3. 设置全局代理
 1) 首先启动软件的服务器：右键图标，选择服务器节点**Vmess-me**,如图所示：
    ![ADSLAP.png](https://s2.ax1x.com/2019/03/30/ADSLAP.png)
 2) 勾选启用http代理，如图所示：
    ![ADSb7t.png](https://s2.ax1x.com/2019/03/30/ADSb7t.png)
 3) 启用pac代理，提升国内访问速度，如图所示：
    ![ADSOtf.png](https://s2.ax1x.com/2019/03/30/ADSOtf.png)

# <center> <font color=#A52A2A size=7>Android翻墙</font></center>

## <font size=6 color=#FF7F50>下载软件</font>

下载v2rayNG,这个软件安卓端还是挺多地方可以下载的

## <font size=6 color=#FF7F50>软件使用</font>

 1) 复制下面的代码
 ```
 vmess://eyJhZGQiOiI2OC4xODMuMjM3LjE3OSIsImFpZCI6IjY0IiwiaG9zdCI6IiIsImlkIjoiYzk3ZTgxYWMtYjY2ZS00OWJjLThjMTMtNjYyNDAzNTFmNjM2IiwibmV0IjoidGNwIiwicGF0aCI6IiIsInBvcnQiOiIyMjU3OSIsInBzIjoibWUiLCJ0bHMiOiIiLCJ0eXBlIjoibm9uZSIsInYiOiIyIn0=
 ```
 2) 打开软件点击右上角的加号，选择**import from lipboard**,如图所示：
 ![ADpUud.jpg](https://s2.ax1x.com/2019/03/30/ADpUud.jpg)

 3) 点击右下角的**V**型符号，就可以使用了。此时手机屏幕上方会有小钥匙图标，如图所示：
 ![ADpaDA.jpg](https://s2.ax1x.com/2019/03/30/ADpaDA.jpg)

# <center> <font color=#A52A2A size=7>IOS(ipad\iphone)翻墙</font></center>

## <font size=6 color=#FF7F50>下载软件</font>

微信公众号搜索**SCDxC**公众号,利用他们提供的共享账号下载**shadowrocket**
他们公众号的使用教程如下：
1. 进入公众号，点击左下角的账号共享--->已购应用。如图所示：
 ![ADuS0K.jpg](https://s2.ax1x.com/2019/03/30/ADuS0K.jpg)
2. 进入已购应用，往下滑，找到小火箭。记住对应的账号。如图所示：
 ![ADnzm6.jpg](https://s2.ax1x.com/2019/03/30/ADnzm6.jpg)
3. 返回公众号主页面，打字输入**账号**两个字，并且发送。如图所示：
 ![ADupTO.jpg](https://s2.ax1x.com/2019/03/30/ADupTO.jpg)
4. 这个时候，公众号会返回一些列的账号的对应的密码。我们要寻找和小火箭对应的那个账号，查看它的密码。这样我们就得到了账号和密码。如图所示：
 ![ADuCkD.jpg](https://s2.ax1x.com/2019/03/30/ADuCkD.jpg)
5. 点开苹果商店(app store)，点击您的头像，然后点击**sign out**。如图所示：
 ![ADuPte.jpg](https://s2.ax1x.com/2019/03/30/ADuPte.jpg)

6. 这个时候，再用我们刚才从公众号得到的账号和密码，点击**sign in**登陆。如图所示：
 ![ADuifH.jpg](https://s2.ax1x.com/2019/03/30/ADuifH.jpg)
7. 登陆成功之后，搜索**shadowrocket**，然后下载它。如图所示：
 ![ADukpd.jpg](https://s2.ax1x.com/2019/03/30/ADukpd.jpg)
8. shadowrocket安装完成之后，我们就可以退出这个账号，登陆自己的账号了。可以参考第5步和第6步

## <font size=6 color=#FF7F50>软件使用</font>

 1) 复制下面的代码
 ```
 vmess://eyJhZGQiOiI2OC4xODMuMjM3LjE3OSIsImFpZCI6IjY0IiwiaG9zdCI6IiIsImlkIjoiYzk3ZTgxYWMtYjY2ZS00OWJjLThjMTMtNjYyNDAzNTFmNjM2IiwibmV0IjoidGNwIiwicGF0aCI6IiIsInBvcnQiOiIyMjU3OSIsInBzIjoibWUiLCJ0bHMiOiIiLCJ0eXBlIjoibm9uZSIsInYiOiIyIn0=
 ```
 2) 打开软件会自动识别剪切板的代码,如图所示：
 ![AD9iKH.png](https://s2.ax1x.com/2019/03/30/AD9iKH.png)

 3) 打开vpn，就可以使用了。此时手机屏幕上方会有vpn图标

























