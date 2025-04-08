---
title: 使用 Mihomo(Clash) 搭建透明网关，使局域网设备科学上网
tags:
  - Clash
  - Mihomo
  - 科学上网
categories:
  - 其他
date: 2025-04-08 14:34:13
---
> 本文只探讨在 Linux 设备下（如树莓派、迷你主机）开启 Clash，并将该设备作为透明网关供家庭其他设备使用这一场景，本文需要一定的网络原理基础。

# 0. 什么是透明网关

如果一个设备想要科学上网，那么他可以在本机安装代理工具来进行网络访问。但是在一个局域网中，网关是可以自定义的，我们可以将希望科学上网的设备网关指向一台可以转发网络流量的设备，从而让这个设备帮我们把流量转发给代理工具，并让代理工具访问到资源后再返回给设备，这就实现了局域网设备无需安装任何代理工具就能实现科学上网的需求。

![image.png|686](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202504081652374.png)

其实“透明网关”和“旁路由”类似，都是非标准术语，只是社区上都这么叫。只是一般我们讲透明网关强调的是数据转发、拦截的功能，而旁路由可能还有 DHCP、NAT 等功能，旁路由安装了 OpenClash 之类的插件也能实现透明网关的功能。

> 讲一下为啥不用 OpenClash 来做代理实现同样的功能，因为 OpenClash 设置太复杂了，并且我这边使用的效果会影响局域网内其他设备的网络访问，造成整个局域网都很慢，感觉有很多 BUG。并且 OpenWrt 的资源占用也不低，单纯为了实现透明网关的数据代理不如只用一个轻量的 Linux 系统 + Clash/Mihomo 核心来实现。

# 1. Clash 端开启 TUN Mode

## 1.1 使用 Clash（不推荐）

安装 Clash permium 版本： https://github.com/Dreamacro/clash/releases/tag/premium

> 注意：开源的普通版本不支持 TUN Mode，无法搭建透明网关

Clash 2022 年 3 月的更新在 TUN Mode 的配置中加入了 `auto-route` 与 `auto-detect-interface` 两项配置，极大的方便了 Linux 设备开启 TUN 模式，不需要再额外设置 iptables 与 tproxy。

首先在 Clash 配置文件中写入 DNS 与 TUN 配置：

```yaml
dns:
  enable: true
  listen: 0.0.0.0:53
  enhanced-mode: fake-ip
  nameserver:
    - 114.114.114.114
    - 223.5.5.5
    - 8.8.8.8
tun:
  enable: true
  stack: system
  dns-hijack:
    - any:53
    - tcp://any:53
  auto-route: true
  auto-detect-interface: true
```

此时再执行 Clash 服务时就已经开启了 TUN Mode。

## 1.2 使用 Mihomo（建议）

由于 Clash 作者删库跑路了，Clash.Meta 项目也换了个名字叫 Mihomo 继续维护，因此我们将会使用 Mihomo 来实现透明代理功能。

按照官方教程下载 Mihomo 核心，并将其注册为系统服务：

- 下载：[https://wiki.metacubex.one/startup/](https://wiki.metacubex.one/startup/)
- 注册为系统服务：[https://wiki.metacubex.one/startup/service/](https://wiki.metacubex.one/startup/service/)

# 2. 开启流量转发

在 Linux 环境下，默认是不转发流量的，也就是说如果将当前设备作为网关，是无法正常上网的。

编辑 /etc/sysctl.conf 文件

```sh
vim /etc/sysctl.conf
```

将以下代码取消注释

```sh
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
```

加载内核参数

```sh
sysctl -p
```

然后我们要在想使用透明代理的设备上进行如下设置（以 IOS 为示例）：

- 在 Wifi 详情中，『配置IP』选项选择手动：
	- 『IP地址』输入一个内网地址，即手动为你的设备分配一个内网 IPv4 的地址；
	- 『子网掩码』输入 255.255.255.0；
	- 『路由器』输入运行 Clash 的设备的内网地址；
- 选择『配置DNS』为手动，并添加服务器，IP 为当前运行 Clash 的设备的内网地址；

按道理来讲的话进行这样的设置后即可让内网设备发送的数据包都被 Clash 进行代理，但是，由于 Linux 环境比较复杂，你可能会出现手机还是无法访问外网的情况，那么就要继续看下去这篇文章了。

开启 TUN Mode 后，可能会遇到 [`dns-hijack` 失败的情况](https://github.com/Dreamacro/clash/issues/2671)（如 Ubuntu 22），具体的表现为访问 [Clash 控制面板](http://clash.razord.top/) 的日志选项时，会发现所有的域名规则都失效了，请求会直接落到 IP 请求规则上，最后匹配到兜底的 MATCH 规则。

要想搞清楚原因，就要明白在 Linux 系统的 DNS 解析到底经过了什么流程：

- 首先用户对一个域名发起 HTTP 请求前，会首先发起 DNS 解析请求；
- Linux 在发起 DNS 解析请求时，会参照 `/etc/resolv.conf` 文件的配置来进行请求，这个文件中配置了 DNS 解析的服务器、超时时间、传输协议等信息，比如 nameserver 定义了DNS 服务器为 `8.8.8.8`，那么 DNS 请求就会发送给 `8.8.8.8` 这个服务器（DNS 请求是一个 UDP 请求，并且访问的是 53 端口）；
- DNS 请求完毕，获取到目标 IP；
- 构建 HTTP 请求报文，才向目标服务器发送请求。

但是在常见的 Linux 发行版中，为了优化 DNS 请求（比如缓存 DNS）以及进行一些其他操作，`resolv.conf` 文件的控制权可能被其他应用拦截，以 Ubuntu 为例，`resolv.conf` 文件时由 `systemd-resolved` 控制的，当你去尝试直接修改该配置文件时，就会出现如下警告：

```
# This is /run/systemd/resolve/stub-resolv.conf managed by man:systemd-resolved(8).
# Do not edit.
#
# This file might be symlinked as /etc/resolv.conf. If you're looking at
# /etc/resolv.conf and seeing this text, you have followed the symlink.
#
# This is a dynamic resolv.conf file for connecting local clients to the
# internal DNS stub resolver of systemd-resolved. This file lists all
# configured search domains.
#
# Run "resolvectl status" to see details about the uplink DNS servers
# currently in use.
#
# Third party programs should typically not access this file directly, but only
# through the symlink at /etc/resolv.conf. To manage man:resolv.conf(5) in a
# different way, replace this symlink by a static file or a different symlink.
#
# See man:systemd-resolved.service(8) for details about the supported modes of
# operation for /etc/resolv.conf.
```

这个意思是如果你直接修改了这个文件，那么就会影响到 `systemd-resolved`，并且你修改了也是没有用的，在服务重启后，`systemd-resolved` 就会重写这个文件，你做的变更不会被保留下来。

经过 `systemd-resolved` 的修改，`resolv.conf` 文件的 `nameserver` 配置会被设置为 `127.0.0.53`，可以很容易的发现，这并不是一个线上的 DNS 服务器，而是一个本地 IP，这个就是  `systemd-resolved` 创建的本地 DNS 解析服务器。如果是在一个局域网中，`systemd-resolved` 还会把 DNS 服务器的目标地址再转为路由器（网关）的IP。这样就形成了如下的流程：

- 发起 DNS 请求
- DNS 请求目标地址为 `127.0.0.53:53`，即  `systemd-resolved` 的本地 DNS 服务器
- 检查本地 DNS 服务器有无缓存，如果没有缓存，转发给路由器（网关）的 DNS 服务器（如 192.168.123.1）
- 检查网关层有无缓存，如果没有缓存才将请求转发给公网 DNS 服务器，如 `114.114.114`

那么 Clash 的 dns-hijack 有一个很重要的特性，就是 **dns-hijack 不会去拦截本地的 DNS 服务器**。我们不难发现，经过 `systemd-resolved` 的操作，DNS 请求在本机发出请求的目标 IP 为路由器（网关）的IP，这就不难解释为什么 dns-hijack 失效了，因为 Clash 全程都没有拦截到任何一个向公网发出的 DNS 请求，真正的 DNS 请求都交给路由器（网关）处理了。经过处理后的 DNS 请求转化成 IP 之后再发出 HTTP 请求，所以 Clash 拿到的只是一个目标 IP，这也解释了为什么所有的域名规则匹配失败了。

综上，解决这个问题有两个方案：

## 2.1 完全拦截系统 DNS 服务（不建议）

简单粗暴，直接禁用 `systemd-resolved`：

```sh
systemctl disable systemd-resolved
```

如果还不行就手动在 `resolv.conf` 文件中将 `nameserver` 设置为一个外网的 DNS 服务器 IP（如 8.8.8.8），这样 DNS 请求都会被 Clash 的 dns-hijack 拦截，然后返回 fake-ip，执行匹配规则等后续流程。

但这样有个问题，当 Clash 关闭后，这台机子就完全无法联网了，同时，关闭 `systemd-resolved` 可能会造成一些其他问题（比如桌面端的 Ubuntu 无法正常的显示网络连接图标等）。

那么就需要使用一个侵入性较小的方案

## 2.2 手动指定 systemd-resolved 的 nameserver（不建议）

既然 Clash 无法拦截本地 DNS 请求，那就保证 DNS 在网卡发出的请求目标地址不要为路由器（网关）的 IP就可以了，这个通过修改 `systemd-resolved` 服务的配置文件可以实现。

打开 `/etc/systemd/resolved.conf` 文件，并修改 nameserver 为任意一个外网 IP，这样 DNS 请求就不会转发给路由器了，而是直接尝试向外网 DNS 服务器发起请求，这样就可以被 Clash 拦截到了~

但此时还有些小问题，如果我们直接请求外网 DNS 服务器，那我们在路由器 host 中配置的本地域名就无法读取到了，我们可以将 Clash 的 DNS 服务器列表中手动加上路由器 IP 来解决。

此时如果使用透明代理的方式，需要将设备的 DNS 修改为任意一个外网 DNS 服务器 IP，**不能设置为 Clash 部署机子的内网 IP 了**，否则还是会导致 Clash 无法拦截 DNS 请求。

## 2.3 开启 Sniffer 域名嗅探器（推荐）

> 注意只有 mihomo、clash.meta 才有此功能。

如下是目前一个比较完美的透明网关配置，无需处理 `systemd-resolved`：

```yaml
# 是否允许内核接受 IPv6 流量
ipv6: true
# 允许其他设备经过 Clash 的代理端口
allow-lan: true
# 开启统一延迟时，会计算 RTT，以消除连接握手等带来的不同类型节点的延迟差异
unified-delay: false
# TCP 并发
tcp-concurrent: true

# 控制是否让 Clash 去匹配进程，设置为 strict，由 Clash 判断是否开启
find-process-mode: strict
# 全局 TLS 指纹，优先低于 proxy 内的 client-fingerprint
global-client-fingerprint: chrome

profile:
  # 储存 API 对策略组的选择，以供下次启动时使用
  store-selected: true
  # 储存 fakeip 映射表，域名再次发生连接时，使用原有映射地址
  store-fake-ip: true

# 域名嗅探：https://wiki.metacubex.one/config/sniff/
# 用于解决流量到达 Clash 时只有 IP 没有域名的问题
sniffer:
  enable: true
  sniff:
    HTTP:
      ports: [80, 8080-8880]
      override-destination: true
    TLS:
      ports: [443, 8443]
    QUIC:
      ports: [443, 8443]
  skip-domain:
    - "Mijia Cloud"
    - "+.push.apple.com"

# 开启虚拟网卡处理流量
tun:
  enable: true
  stack: mixed
  dns-hijack:
    - "any:53"
    - "tcp://any:53"
  auto-route: true
  auto-redirect: true
  auto-detect-interface: true

# 开启 Clash 内置的 DNS 服务，嗅探服务需要用到
dns:
  enable: true
  ipv6: true
  enhanced-mode: fake-ip
  fake-ip-filter:
    - "*"
    - "+.lan"
    - "+.local"
    - "+.market.xiaomi.com"
  default-nameserver:
    - tls://223.5.5.5
    - tls://223.6.6.6
  nameserver:
    - https://doh.pub/dns-query
    - https://dns.alidns.com/dns-query
```

这里简单讲一下数据通过 Mihomo/Clash 的流程：

1. 局域网设备请求 google.com，发起 DNS 请求；
2. DNS 请求转发到透明代理层，被 Mihomo 的 DNS 服务拦截，Mihomo 发现使用的是 fake-ip 模式同时启用了域名嗅探，就会生成一个在记录中唯一的虚假 ip 地址提供给局域网设备，并在映射表中记录下 fake-ip 和域名的对应关系；
3. 局域网设备获取到 DNS 返回的 IP 后浏览器向目标 IP 发起请求；
4. 数据包再次来到透明代理，此时透明代理通过数据包只能看到 IP，看不到请求的真实域名，但是由于第二步中记录了 fake-ip 对应的真实域名，因此读取映射表获取真实 IP；
5. 按照 Mihomo 的节点规则配置，进行域名规则匹配，如果匹配到敏感域名则走代理节点。域名无匹配规则时则会发起本地或者远程 DNS 请求（这里不太清楚逻辑）获取真实 IP，再根据 GEOIP 信息选择走节点代理还是走本地流量；

这里需要注意：tun、dns、sniffer 是必须配置的，否则会出现网络无法访问、DNS 请求失败、https 证书返回了其他网站的等奇怪的问题。

关于 DNS 劫持、fake-ip、域名嗅探等细节，可以观看视频：[https://www.youtube.com/watch?v=aKlH6KRt9Jc&t=911s&ab_channel=%E4%B8%8D%E8%89%AF%E6%9E%97](https://www.youtube.com/watch?v=aKlH6KRt9Jc&t=911s&ab_channel=%E4%B8%8D%E8%89%AF%E6%9E%97)

# 3. 已知问题

如果禁用了系统的 dns 服务，会导致在 clash 服务启动之前的所有服务的 dns 查找都崩溃，比如 nginx、frpc 等。解决方法是在 clash 服务启动之后再启动其他的服务。

此外，如果使用了 homeassistant，Homekit 插件也会因为 Clash 对 DNS 的干扰，导致配件无响应。解决方法是先启动 Homeassistant，然后再启动 Clash。

参考教程：

- [Clash 旁路由透明网关](https://lvv.me/posts/2022/09/12_clash_as_router/)
- https://little-star.love/posts/5d083060