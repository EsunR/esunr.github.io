---
title: 小米路由器mini刷入Padavan教程
tags: []
categories:
  - Front
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