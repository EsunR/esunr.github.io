---
title: Clash 使用教程
tags: []
categories:
  - 其他
date: 2022-08-02 17:41:40
---

# 1. 原理篇

## 1.1 Clash 是个啥

Clash 是一个多平台的、支持 v2ray 的**代理转发客户端**，它可以将你设备的网络请求**按照一定的规则**转发到代 `理服务器上`。

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

由于 [Clash](https://github.com/Dreamacro/clash) 作者更新不力，对于使用了新协议（如 vless）的节点，无法进行支持，因此社区退出了基于 Clash 改版的 [Clash.Meta](https://github.com/MetaCubeX/Clash.Meta) 内核，以提供更多的节点协议支持，因此现阶段（2023.5.19 推荐使用支持 Clash.Meta 内核的客户端）。

> 这里说明以下为什么要使用新协议，在2023年10月3日出现了大批量节点被封禁的情况，据传言网络审查者借助大数据与人工智能的手段，**已经能够精确识别到当前用户是否正在采用非法手段使用网络（如使用 vmess 协议的节点）**，因此社区对于旧有的基于 tls in tls 伪装思路究竟是否安全产生了很多质疑声。

> 然而旧协议的代表 vmess 的作者已经退出，ProjectV 项目也已经被废弃，一艘大船已经几近沉没，于是更多人参与到了 ProjectX，搭建一艘新的巨轮。ProjectX 推出了更多的协议类型，如效率更高的 vless+xtls ，2023年1月9日还推出了隐蔽性更高的 reality 协议，至此 reality 协议被视为一种更好的解决方案。

## 2.1 Windows/MacOS 客户端

#### Clash for Windows （不再推荐使用，建议下载下面的 clash-verge）

[下载地址](https://github.com/Fndroid/clash_for_windows_pkg/releases)

![](https://s2.loli.net/2022/08/02/B8LcF7dpPEMGz1S.png)

#### clash-verge

> clash 与 clash.meta 双内核，支持使用 reality 节点

[下载地址](https://github.com/zzzgydi/clash-verge/releases)

版本下载说明与上面一致，不再添加截图。

## 2.2 Android 客户端

#### ClashFroAndroid（不再推荐使用，建议下载下面的 ClashMetaForAndroid）

如果可以使用 Google Play，优先在 Google Play 上下载发行版本，[下载地址](https://play.google.com/store/apps/details?id=com.github.kr328.clash)

如果无法访问 Google Paly，从 Github 下载，[Clash for Android 下载地址](https://github.com/Kr328/ClashForAndroid/releases)

![](https://s2.loli.net/2022/08/02/kLfzv24TcylutIK.png)

#### ClashMetaForAndroid【支持 reality 节点】

[下载地址](https://github.com/MetaCubeX/ClashMetaForAndroid/releases)

版本下载说明与上面一致，不再添加截图。

## 2.3 IOS

#### Stash

注册美区账号，APP Store 搜索 Stash 并购买下载（不能使用国内信用卡，需要买礼品卡兑换，自行 Google 关键词 『Stash 兑换码』，30RMB左右，也可以直接购买成品号）

下载时认准 app 图标和开发者：

![](https://s2.loli.net/2023/03/30/bFnDBpZ8mrwdJVv.jpg)

#### ShadowRocket

注册美区账号，APP Store 搜索 ShadowRocket 并购买下载。

# 3. 使用

## 3.1 Clash for Windows（无论使用哪个软件，先看这个软件的使用方法）

### 订阅的下载与更新

![](https://s2.loli.net/2022/08/02/U8my16PI5vX4oMK.png)

### Proxies 面板

#### Rule 规则模式

**一般默认使用的代理模式**，在这个模式下，所有流量都会按照制定的规则进行转发，比如国内流量不转发，国外流量再进行转发，这样就可以尽可能的节省代理服务器的流量，同时保证国内服务能够正常访问，以下为部分规则的说明与示例。

节点选择与自动选择：

![](https://s2.loli.net/2022/08/02/R7njxksUNdYrXE8.png)

其他规则：

![](https://s2.loli.net/2022/08/02/D4z5sgxmZl8CIAk.png)

举例，如果你想看 B 站港区番剧，你可以手动调整规则列表中的『Bilibili』为香港节点（看完之后记得切回直连，否则浪费带宽，自己速度还慢，相当于从国外绕回国内）：

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

## 3.2 clash-verge

切换中文：

![](https://s2.loli.net/2023/05/19/2gbI6PoX5BDqaJQ.png)

切换为 ~~Meta~~(新版为 Mihomo) 内核，并启用系统代理与开机自启：

![](https://s2.loli.net/2023/05/19/xoJyAZ4l9iXgHKc.png)

> 其他操作与 Clash for Windows 一致，不再赘述

## 3.3 ClashForAndroid

![](https://s2.loli.net/2022/08/02/H5Vj23ziYOqbZka.jpg)

> 代理规则与 Clash for Windows 相同，不再赘述

## 3.3 ClashMetaForAndroid

与 ClashForAndroid 界面和操作一致，不再赘述

## 3.5 Stash

![](https://s2.loli.net/2023/03/30/DU2hXSufmpgVJtN.jpg)

> 代理规则与 Clash for Windows 相同，不在赘述

## 3.6 ShadowRocket

进入 APP 后依次添加订阅，选择节点，开启代理：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202403271912750.png)