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

同时由于 53 端口可能被占用，因此需要关闭默认的系统 dns 端口：

```sh
systemctl disable systemd-resolved
```

配置完成后就可以进入设备的 wifi 设置，修改网关地址（路由器地址）为你的 Linux 设备在局域网中的 IP 地址，同时将 DNS 服务也设置为 Linux 设备的 IP 地址，这样设置好的设备就可以进行科学上网了。

# 3. 已知问题

如果禁用了系统的 dns 服务，会导致在 clash 服务启动之前的所有服务的 dns 查找都崩溃，比如 nginx、frpc 等。解决方法是在 clash 服务启动之后再启动其他的服务。

此外，如果使用了 homeassistant，Homekit 插件也会因为 Clash 对 DNS 的干扰，导致配件无响应。解决方法是先启动 Homeassistant，然后再启动 Clash。

参考教程：

- [Clash 旁路由透明网关](https://lvv.me/posts/2022/09/12_clash_as_router/)
- https://little-star.love/posts/5d083060