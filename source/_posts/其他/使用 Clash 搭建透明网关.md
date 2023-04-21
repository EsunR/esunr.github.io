---
title: 使用 Clash 搭建透明网关
tags:
  - Clash
categories:
  - 其他
date: 2023-04-16 14:34:13
---
> 本文只探讨在 Linux 设备下（如树莓派、迷你主机）开启 Clash，并将该设备作为透明网关供家庭其他设备使用这一场景。

# 1. Clash 端开启 TUN Mode

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

# 2. 开启流量转发

在 Linux 环境下，默认是不转发流量的，也就是说如果将当前设备作为网关，是无法正常上网的。

开启流量转发需要执行：

```sh
sysctl -w net.ipv4.ip_forward=1
```

或者直接修改 `/etc/systemctl`，将 `net.ipv4.ip_forward=1` 解除注释，并执行 `sysctl -p` 来应用更改。

按道理来讲的话，你只需要手动修改设备 wifi 的网关为当前部署 Clash 服务的机器在内网的 IP，同时将 DNS 服务器 IP 也调整为这台机子的 IP 即可实现透明网关。

但是，由于 Linux 环境比较复杂，你可能会出现手机还是无法访问外网的情况，那么就要检查是不是出现了下面的问题。

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

## 2.1 完全拦截系统 DNS 服务

简单粗暴，直接禁用 `systemd-resolved`：

```sh
systemctl disable systemd-resolved
```

如果还不行就手动在 `resolv.conf` 文件中将 `nameserver` 设置为一个外网的 DNS 服务器 IP（如 8.8.8.8），这样 DNS 请求都会被 Clash 的 dns-hijack 拦截，然后返回 fake-ip，执行匹配规则等后续流程。

但这样有个问题，当 Clash 关闭后，这台机子就完全无法联网了，同时，关闭 `systemd-resolved` 可能会造成一些其他问题（比如桌面端的 Ubuntu 无法正常的显示网络连接图标等）。

那么就需要使用一个侵入性较小的方案

## 2.2 手动指定 systemd-resolved 的 nameserver

既然 Clash 无法拦截本地 DNS 请求，那就保证 DNS 在网卡发出的请求目标地址不要为路由器（网关）的 IP就可以了，这个通过修改 `systemd-resolved` 服务的配置文件可以实现。

打开 `/etc/systemd/resolved.conf` 文件，并修改 nameserver 为任意一个外网 IP，这样 DNS 请求就不会转发给路由器了，而是直接尝试向外网 DNS 服务器发起请求，这样就可以被 Clash 拦截到了~

但此时还有些小问题，如果我们直接请求外网 DNS 服务器，那我们在路由器 host 中配置的本地域名就无法读取到了，我们可以将 Clash 的 DNS 服务器列表中手动加上路由器 IP 来解决。

此时如果使用透明代理的方式，需要将设备的 DNS 修改为任意一个外网 DNS 服务器 IP，**不能设置为 Clash 部署机子的内网 IP 了**，否则还是会导致 Clash 无法拦截 DNS 请求。

# 3. 已知问题

如果禁用了系统的 dns 服务，会导致在 clash 服务启动之前的所有服务的 dns 查找都崩溃，比如 nginx、frpc 等。解决方法是在 clash 服务启动之后再启动其他的服务。

此外，如果使用了 homeassistant，Homekit 插件也会因为 Clash 对 DNS 的干扰，导致配件无响应。解决方法是先启动 Homeassistant，然后再启动 Clash。

参考教程：

- [Clash 旁路由透明网关](https://lvv.me/posts/2022/09/12_clash_as_router/)
- https://little-star.love/posts/5d083060