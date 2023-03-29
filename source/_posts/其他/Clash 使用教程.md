---
title: Clash 使用教程
tags: []
categories:
  - 其他
date: 2022-08-02 17:41:40
---

# 1. 原理篇

## 1.1 Clash 是个啥

Clash 是一个多平台的、支持 v2ray 协议的**代理转发客户端**，它可以将你设备的网络请求**按照一定的规则**转发到代 `理服务器上`。

## 1.2 什么叫代理转发

正常情况下，你的设备访问一个网络服务，是从设备直接发起的网络请求。

![](https://s2.loli.net/2022/08/02/95qkp7yM8b6QNAW.png)

代理转发就是在你和目标服务器之间又架设了一个额外的服务器，称之为 `代理服务器` ，你的网络请求会经过这个 `代理服务器`，它会帮你传达请求数据并返回你想要的数据。

![](https://s2.loli.net/2022/08/02/TFV3q1tNw8J7ngY.png)

## 1.3 代理转发怎么实现科学上网

以 Google 为例，当你正常访问 Google 时，请求会被 GFW 识别，并进行拦截，因此导致你无法正常访问 Google。

![](https://s2.loli.net/2022/08/02/3zx5u2gDKBAvqnQ.png)

但是如果你的流量不是直接访问的，而是先访问没有被 GFW 屏蔽的国外（或国内部分地区）的 `代理服务器`，再由位于国外（或国内部分地区）的 `代理服务器` 对你的流量进行转发，这样就能绕过 GFW，从而正常访问 Google。

![](https://s2.loli.net/2022/08/02/ATvZOEyLJjHdiSr.png)

> 这些 `代理服务器` 在 Clash 中被称作为 `节点` 。

## 1.4 什么是 Clash 订阅

`订阅` 就是群公告里发的链接，Clash 可以读取该订阅链接并下载对应的配置，其包含了 Clash 的代理规则以及代理服务器（服务器节点）点的信息。

Clash 的订阅链接**绝对不能泄露**，否则就会被别人白嫖代理服务器代理，甚至服务器会遭受攻击或被 GFW 封禁。

# 2. 软件安装

## 2.1 Windows/MacOS

[Clash for Windows 下载地址](https://github.com/Fndroid/clash_for_windows_pkg/releases)

![](https://s2.loli.net/2022/08/02/B8LcF7dpPEMGz1S.png)

## 2.2 Android

如果可以使用 Google Play，优先在 Google Play 上下载发行版本，[下载地址](https://play.google.com/store/apps/details?id=com.github.kr328.clash)

如果无法访问 Google Paly，从 Github 下载，[Clash for Android 下载地址](https://github.com/Fndroid/clash_for_windows_pkg/releases)

![](https://s2.loli.net/2022/08/02/kLfzv24TcylutIK.png)

## 2.3 IOS

~~注册美区账号，APP Store 搜索 Choc 并购买下载~~

注册美区账号，APP Store 搜索 Stash 并购买下载

# 3. 使用

## 3.1 Clash for Windows

### 订阅的下载与更新

![](https://s2.loli.net/2022/08/02/U8my16PI5vX4oMK.png)

### Proxies 面板

#### Rule 规则模式

**一般默认使用的代理模式**，在这个模式下，所有流量都会按照制定的规则进行转发，比如国内流量不转发，国外流量再进行转发，这样就可以尽可能的节省代理服务器的流量，同时保证国内服务能够正常访问，以下为部分规则的说明与示例。

节点选择与自动选择：

![](https://s2.loli.net/2022/08/02/R7njxksUNdYrXE8.png)

其他规则：

![](https://s2.loli.net/2022/08/02/D4z5sgxmZl8CIAk.png)

举例，如果你想看 B 站港区番剧，你可以手动调整规则列表中的『Bilibili』为香港节点：

![](https://s2.loli.net/2022/08/02/BjMDuXNqstx1vCS.png)

#### Global 全局模式

如果在 『Rule』规则模式下仍有些国外网站无法访问，你可以选择『Global』全局模式：

![](https://s2.loli.net/2022/08/02/FIyw94MsuZ2kC5L.png)

在这个模式下，你设备的所有流量都会经过你选中的服务器节点（如上图，所有流量都会转发到韩国节点上）。因此全局模式下会消耗大量代理服务器流量，除非特殊情况，否则不要开启。

#### Direct 直连模式

与全局模式相反，如果你发现某些国内网站无法正常访问，就可以选择『Direct』直连模式，这个模式下会临时禁用所有的流量转发，等同于你关闭了 Clash。

![](https://s2.loli.net/2022/08/02/PgDdBcAQ2YnNrlh.png)

### General 面板

General 面板是 Clash for Windows 独有的，一般不用调整。

![](https://s2.loli.net/2022/08/02/CnAoa7tdsrDgzkJ.png)

**\[这段是写给程序员的\]** Port 是代理服务器的端口，一般如果勾选了『System Proxy』，软件就会自动走代理服务器的端口，如果你需要让终端使用 Clash，则按照终端设置代理的方式将代理指向该端口就可以。

单独介绍一下 TUN Mode，TUN Mode 是 Clash for Windows 独有的模式，在非 TUN Mode 模式下，所有的流量只是通过『系统代理』的方式进行代理转发，某些不支持系统代理的软件就无法走 Clash 的代理了，但是在 TUN Mode 下，Clash 会创建一张虚拟网卡，让所有这样就能接管所有的系统流量。举个例子：一般来说游戏的数据包由于走的是 UDP，因此并不会被 Clash 进行转发，但是在 TUN Mode 下，游戏数据包就可以被 Clash 进行转发，因此在 TUN Mode 下，Clash 可以起到游戏加速器的作用。

## 3.2 Clash for Android

![](https://s2.loli.net/2022/08/02/H5Vj23ziYOqbZka.jpg)

> 代理规则与 Clash for Windows 相同，不在赘述

## ~~3.3 Choc 不再推荐，推荐使用 Stash~~

![](https://s2.loli.net/2022/08/02/FmIPugaOUoVWizS.jpg)

> 代理规则与 Clash for Windows 相同，不在赘述