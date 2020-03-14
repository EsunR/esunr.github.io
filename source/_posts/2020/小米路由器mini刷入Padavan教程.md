---
title: 小米路由器mini刷入Padavan教程
tags: []
categories:
  - Other
date: 2020-03-13 15:28:25
---

# 1. 刷入低版本的小米路由器固件并开启 ssh 功能

按照 https://www.youtube.com/watch?v=U1QkNUpuYCg&t=615s 视频教程，到成功 SSH 功能开启的那一步。

> 按照视频中使用 MT 工具箱的方法已经不可用了，所以还是需要刷入 Padavan。

其中老旧版本的固件可以转到 https://mirom.ezbox.idv.tw/miwifi/ 进行下载，小米路由器 mini 可用的固件版本为 `miwifi_r1cm_firmware_5def5_2.17.100` 。

# 2. 刷入 bread

> bread 相当于路由器的引导系统，类似于 Android 的 Recover、TWRP

恩山无线论坛 breed 帖子：[http://www.right.com.cn/forum/thread\-161906\-1\-1.html](https://link.jianshu.com/?t=http://www.right.com.cn/forum/thread-161906-1-1.html)，在里面找到下载地址，然后下载小米 mini 专用[breed\-mt7620\-xiaomi\-mini.bin](https://link.jianshu.com/?t=http://breed.hackpascal.net/breed-mt7620-xiaomi-mini.bin)；接着把 breed\-mt7620\-xiaomi\-mini.bin 用 WinSCP 传到 /tmp 目录，PuTTY 连上路由器并切换目录至 /tmp 准备刷入：

```bash
cd /tmp
mtd -r write breed-mt7620-xiaomi-mini.bin Bootloader
```

刷入后，机器会重新启动，指示灯变蓝，这时需要确保电脑设置为自动获取 IP 地址，并且是用网线连上的路由器。

最后打开 CMD，运行 ping 192.168.1.1 \-t（这时是 ping 不通的），按如下流程：

1，断开小米路由器的电源，用牙签等尖锐物按下路由器 reset 按钮后重新接入电源；
2，等到 mini 路由器的灯开始闪烁或 ping 通时即表明进入 Web 刷机模式，松开 reset 键。

这时在电脑上输入 192.168.1.1，就进入不死 Breed 的控制台了。

# 3. 刷入 Padavan 固件

Padavan 固件可以在 http://opt.cn2qq.com/padavan/ 进行下载，小米路由器 mini 的固件为：

![](http://img.cdn.esunr.xyz/markdown/20200313162829.png)

在 Breed Web 控制台依次选择：固件更新 -> 常规固件 -> 勾选固件复选框 -> 浏览，选择下载好的 Padavan 固件上传，刷入搞定！

注意，此时在启动方式里面选择的是普通固件，如果想刷回小米原厂固件，进入“固件启动设置页面”，将固件类型选择为“小米 Mini”保存，然后就可以完美启动小米 Mini 原厂固件了，而且可以使用串口 (TTL) 登录。

刷机完成后浏览器输入 `http://192.168.123.1/` 进入 Padavan 系统管理界面

# 4. 网络设置

我刷入 Padavan 的目的是为了做无线 AP ，同时又希望接入该 AP 的设备能够使用 SSR。

为了达到这个需求，首先不能使用 Padavan 中的纯 AP 模式（也就是使用 LAN 模式作为 AP-Client 角色），这样就无法使用 SSR 的功能，原因很简单，因为纯 AP 的模式下，AP 路由需要关闭 DHCP 服务，AP 的 IP 以及网关地址都是静态的，需要与我们的主路由（也就是当前网络中的网关设备）位于同一 IP 频段下。因此纯 AP 的模式仅仅是放大了主路由的信号，当新设备接入 AP 并进行网络传输时，AP 将数据包直接转发给主路由，并不会经过 Padavan 的 SSR 服务，因此 AP 下的 SSR 服务虽然能够正常运行，但实际上并没有效果。其网络结构如下：

![](http://img.cdn.esunr.xyz/markdown/20200314233522.png)

因此我们要使用 WAN 模式作为 AP-Client 的角色，WAN 模式就相当于我们的 AP 连接上了主路由器之后，在加入 AP 的设备跟主路由位于不同的频段，这个频段是 AP 创建的一个新频段，如：我们主路由器的频段为 `192.168.31.x` 那么 AP 的新频段为 `192.168.123.x`。在这个模式下，AP 路由的 IP 地址是动态的，同时 AP 端也需要开启 DHCP 服务（为了给连接 AP 的设备分配 IP 地址），就可以正常使用 SSR 服务。其网络结构如下：

![](http://img.cdn.esunr.xyz/markdown/20200314233322.png)

但是 WAN 模式的缺点是访问其管理页面时，`192.168.123.1` 这个访问地址只能在 AP 网络下进行访问，要是想要在主网络环境下无法访问其管理页面，同时 FTP 以及 SAMBA 服务也不能在主网络环境下进行访问。

进行如下设置即可使用 WAN 模式进行 AP 桥接：

![](http://img.cdn.esunr.xyz/markdown/20200314234907.png)

> 注意：在 WAN 模式下，内网设置要保持 DHCP 服务的开启