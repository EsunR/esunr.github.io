---
title: Surface Pro 6 日常使用问题记录
tags: []
categories:
  - Other
date: 2019-11-24 17:13:35
---

# 1. 屏幕低亮度闪屏问题

按以下顺序找到0000文件夹：

`[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000]`

然后找FeatureTestControl注册表修改数值数据9250

# 2. CPU 锁频 0.4 Ghz

开机后按住电源 15s **强制关机**，关机后按住电量上键，再点按一下开机键，等待进入 UEFI 界面，点击重启设备。原理是这样可以清除硬件缓存。

# 3. 蓝牙鼠标卡顿

暂时无解