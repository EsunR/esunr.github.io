---
title: 不花一分钱，把老旧安卓手机改为Linux服务器，并实现内网穿透
tags: [Linux]
categories:
  - 运维
date: 2021-12-11 22:15:38
---
# 0. 前言

前一阵子，突然想搞个树莓派玩玩，但是一看某宝，之前顶天也就300块钱的树莓派现在竟然四五百起，新款的都到七八百了，闲鱼也都要价要疯了。

作为不可能多花一分钱给黄牛的我，突然想要家里还有太不用的小米 mix3（淘一台二手手机也比买树莓派强啊），要是能发挥这台手机的性能，那不比树莓派高多了！

因此经过一番折腾，成功在手机上装上了完整版的 CentOS，并且做了内网穿透，安装了 Home Assistant，并且全程不！花！一！分！钱！

但是过程还是比较坎坷的，因此整理了一下安装以及内网穿透的流程，在此分享一下。

# 1. Linux Deploy

## 1.1 安装

Linux Deploy 是一个基于 chroot 让安卓运行完整的 Linux arm 系统的工具，但前提是使用该应用手机必须 Root。

> 如果你的手机没有 Root，可以使用 Termux，借助 [proot-distro](https://github.com/termux/proot-distro) 这个项目来安装 Linux arm 系统。但是笔者这里没有安装成功，从而转向了 Linux Deploy。

除了 Linux Deploy，你还需要安装：

- BusyBox：提供基础的软件包服务（大概吧这点我也不懂），否则 Linux Deploy 可能会安装失败
- Termux：一个安卓终端，可以调用 ssh 连接，也可以用于辅助我们查看一些系统信息

这里推荐一个视频安装教程（视频里安装的是 Ubuntu，但是本文章全程用的是 Centos）：

[手机安装linux系统-手机秒变服务器（Linux Deploy）](https://www.bilibili.com/video/BV1oA411b7Fb)

需要注意以下几点：

- 安装过程中保证全程科学上网环境
- 一定要分配镜像大小，否则在安装过程中可能会漏装一些系统依赖，导致系统无法启动
- extra/ssh 必须显示 done 才说明系统安装并启动成功了
- 如果始终无法启动成功系统，尝试安装别的 Linux 发行版本（笔者这里就无法启动 Ubuntu，但是 Centos 就启动成功了）
- 用户名记得设置为 `root`

安装完成之后，打开 Termux，输入 `ip addr | grep inet` 获取本机在内网环境下的 IP 地址：

![](https://s2.loli.net/2021/12/11/Br3QuSoUg52Fmxd.png)

之后就可以使用 ssh 指令连接到 Linux Deploy 启动的系统了，比如我这里就是：

```shell
ssh root@192.168.0.138
```

我们后续的操作都会在终端中进行。

## 1.2 chroot 环境下如何使用 systemctl

> `systemctl` 服务可以将应用作为系统守护进行，也可以用于设置应用开机自启。

正常来说，我们应该执行 `systemctl start <service name>` 来启动 service 服务，比如

```
systemctl start nginx # 启动 nginx
systemctl enable nginx # 将 nginx 设置为开机自启
```

但是 chroot 环境中无法使用 systemctl，可以用下面的 servicectl 项目代替：

[https://github.com/smaknsk/servicectl](https://github.com/smaknsk/servicectl)

首先进行安装：

```shell
wget https://github.com/smaknsk/servicectl/archive/1.0.tar.gz
tar -xf 1.0.tar.gz -C /usr/local/lib/
ln -s /usr/local/lib/servicectl-1.0/servicectl /usr/local/bin/servicectl
ln -s /usr/local/lib/servicectl-1.0/serviced /usr/local/bin/serviced
```

安装完成之后就可以使用 `servicectl` 代替所有的 `systemctl` 指令了。

`servicectl` 虽然可以帮助我们设置开机自启，但是其本身也必须在系统启动前启动，然后才能拉起所有设置了开机自启的应用。Linux Deploy 的设置中有一个 `初始化` 选项，开启后 Linux Deploy 在启动系统后会执行一段用户可以编辑的脚本，该脚本的默认位置在 `/etc/rc.locl`。

我们首先要在 Linux 系统中为初始化脚本写入执行权限权限：

```shell
chmod 777 /etc/rc.locl
```

然后编辑该脚本的内容，向内写入 `serviced`：

```shell
# /etc/rc.locl
serviced
```

# 2. 内网穿透

## 2.1 安装 nginx

安装 nginx 这一步不再多说，基本上都会，安装完成后调用:

```shell
servicectl start nginx
servicectl enable nginx
```

## 2.2 蜻蜓映射

推荐使用蜻蜓映射来映射 http 服务，因为其可以免费绑定一个你自己的域名，并且支持 https。

官方网站[https://flynat.51miaole.com/](https://flynat.51miaole.com/)

按照提示安装客户端：

![](https://s2.loli.net/2021/12/09/r8D3AYwXaUCyG5k.png)

由于这个公司已经很久没有维护该项目，导致它的自动启动指令是无效的，因此我们要自己编写自动启动脚本。

首先要安装 `screen` 可以让我们后台启动一个命令行空间来跑应用（类似 nohup，但是 screen 可以让我们随时查看执行应用的屏幕信息，并且内网穿透的应用在开机时使用 nohup 可能无法正常启动）:

```
yum install screen
```

将下面的代码写入到 `/usr/lib/systemd/system/flynatc.service` 中，注意要将 `<username>` 和 `<token>` 分别替换为你自己蜻蜓映射总览页面的用户名与 Token：

```
# Centos 7
# 存放位置 /usr/lib/systemd/system
# 开启 servicectl start flynatc
# 关闭 servicectl stop flynatc
# 开机启动 servicectl enable flynatc
# 取消开机启动 servicectl disable flynatc

[Unit]
Description=Flynat Service
Wants=network-online.target
After=network.target

[Service]
Type=simple
ExecStart=screen -d -m /usr/local/flynat/flynatc -u <username> -k <token>
# Suppress stderr to eliminate duplicated messages in syslog. NM calls openlog()
# with LOG_PERROR when run in foreground. But systemd redirects stderr to
# syslog by default, which results in logging each message twice.
StandardOutput=syslog
StandardError=null

[Install]
WantedBy=multi-user.target
```

启动映射：

```shell
servicectl start flynatc
```

开启开机自启：

```shell
servicectl enable flynatc
```

## 2.3 网云穿

网云穿也是一个内网穿透服务，其提供了一个免费域名，并且免费域名是不会变的，因此特别适合作为 ssh 服务的穿透工具。

官网：[https://xiaomy.net/](https://xiaomy.net/)

注册完成之后可以申请一条免费隧道，按照如下设置来映射我们本机的 ssh 服务端口：

![](https://s2.loli.net/2021/12/11/D5SMEnZLk9HO6ow.png)

然后在你的终端内下载网云穿的内网穿透服务，并将其放到一个你能找到的地方（这里我就放到 `~` 目录下了）：

```shell
cd ~
wget https://down.xiaomy.net/linux/wyc_linux_arm
chmod 777 ./wyc_linux_arm # 设置软件执行权限
```

然后调用：`./wyc_linux_arm token=<token>`（token 就是你控制台中刚才创建的那条隧道的令牌）

![](https://s2.loli.net/2021/12/11/CDeg2NuKRY3lFQi.png)

服务启动成功后就可以使用 ssh 指令来测试一下：

```
ssh root@<域名> -p <外网端口>
```

如果正常连接就可以按照蜻蜓映射那样创建一个 service 脚本到，你可以直接复制下面写好的脚本（记得替换 token）并将其命名为 `wcy.service`，放到 `/usr/lib/systemd/system/` 中：

```
[Unit]
Description=Wcy Service
After=network.target

[Service]
Type=simple
ExecStart=screen -d -m ~/apps/wyc/wyc_linux_arm -token=mjxopf92
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

启动映射：

```shell
servicectl start wcy
```

开启开机自启：

```shell
servicectl enable wcy
```