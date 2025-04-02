---
title: 使用防火墙与 fail2ban 防止公网服务器被攻击
tags:
  - Linux
  - 网络安全
categories:
  - Linux
date: 2025-04-02 11:30:00
---
# 1. 自查服务器是否正在遭受攻击

我们将服务器的端口直接暴露在公网环境是比较危险的，服务器可能一直在遭受外部网络的扫描，你可以通过应用日志或者防火墙日志来自查端口是否有人在尝试进行密码爆破或者端口扫描。

以 SSH 登录为例，你可以执行 `sudo tail -f  /var/log/auth.log` 实时输出日志查看是否正在有人尝试使用 ssh 登录，如下就是一个典型 ssh 登录失败日志，IP 为 196.251.67.42 的用户一直在尝试使用 root 用户进行登录：

```
Apr  2 15:05:34 cloud sshd[34625]: Failed password for root from 196.251.67.42 port 44972 ssh2
Apr  2 15:05:34 cloud sshd[34625]: Received disconnect from 196.251.67.42 port 44972:11: Bye Bye [preauth]
Apr  2 15:05:34 cloud sshd[34625]: Disconnected from authenticating user root 196.251.67.42 port 44972 [preauth]
Apr  2 15:05:38 cloud sshd[34627]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=196.251.67.42  user=root
Apr  2 15:05:41 cloud sshd[34627]: Failed password for root from 196.251.67.42 port 44982 ssh2
Apr  2 15:05:42 cloud sshd[34627]: Received disconnect from 196.251.67.42 port 44982:11: Bye Bye [preauth]
Apr  2 15:05:42 cloud sshd[34627]: Disconnected from authenticating user root 196.251.67.42 port 44982 [preauth]
Apr  2 15:15:38 cloud sudo:     root : TTY=pts/1 ; PWD=/root ; USER=root ; COMMAND=/usr/bin/tail -f /var/log/auth.log
Apr  2 15:15:38 cloud sudo: pam_unix(sudo:session): session opened for user root by root(uid=0)
```

> RedHat/CentOS 日志为 `/var/log/secure`

你也可以使用 `sudo cat /var/log/auth.log | grep "Failed"` 单独过滤出来哪些登录失败的日志：

```
Apr  2 14:25:16 cloud sshd[34106]: Failed password for invalid user xiaoli from 80.94.95.112 port 10340 ssh2
Apr  2 14:25:19 cloud sshd[34106]: Failed password for invalid user xiaoli from 80.94.95.112 port 10340 ssh2
Apr  2 14:25:22 cloud sshd[34106]: Failed password for invalid user xiaoli from 80.94.95.112 port 10340 ssh2
Apr  2 14:26:50 cloud sshd[34119]: Failed password for root from 92.255.85.188 port 61284 ssh2
Apr  2 14:34:57 cloud sshd[34209]: Failed password for invalid user user from 103.197.184.12 port 15840 ssh2
```

如果你开启了防火墙，可以通过防火墙的拦截日志来侧面看出服务器被扫描端口的严重程度。以 ufw 为例：

1. 使用 `ufw logging on` 启用实时日志；
2. 使用 `tail -f /var/log/ufw.log` 查看 ufw 的日志；

```
Apr  2 15:27:34 cloud kernel: [189619.367923] [UFW BLOCK] IN=ens3 OUT= MAC=32:1c:6e:bf:7a:45:48:a9:8a:a2:7e:fe:08:00 SRC=195.178.110.220 DST=xxx.xxx.xxx.xxx LEN=60 TOS=0x00 PREC=0x00 TTL=48 ID=59696 DF PROTO=TCP SPT=50196 DPT=6000 WINDOW=32120 RES=0x00 SYN URGP=0
```

上面这行日志说明，195.178.110.220 正在向 xxx.xxx.xxx.xxx（也就是本机）的 6000 端口上发送 TCP 握手请求，但是被 UFW 拦截了，因为 UFW 未开放此端口。

# 2. 如何防止服务器被攻击

## 2.1 开启防火墙

开启防火墙是重中之重，这里简单讲解一下 `netfilter`、`iptables`、`nfw` 等几个常见的与防火墙相关的工具，以及他们的关系：

### netfilter

`netfilter` 是 Linux 内核层的一个模块，负责提供网络数据包过滤、NAT 等功能，同时提供了多个挂载点，如 PREROUTING、INPUT、OUTPUT 等（完整的 hook 如下图，左侧绿框代表外部网络，右侧蓝框代表系统内部网络，中间区域即为防护墙）。`netfilter` 本身不提供数据包的过滤规则，只是系统底层的一个接口，因此我们不会直接使用 `netfilter` 来管理防火墙规则。

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202504021130341.png)

### iptables 与 nftables

`iptables` 是一个命令行工具，用户可以按照一定的语法编写防火墙规则，`iptables` 会将这些规则实现在 `netfilter` 的各个 hook 上，达到数据包丢弃、拦截等防火墙的功能。

`iptables` 使用 table 来组织规则，根据**用来做什么类型的判断**（the type of decisions they are used to make）标准，将规则分为不同 table。例如，如果规则是处理 网络地址转换的，那会放到 `nat` table；如果是判断是否允许包继续向前，那可能会放到 `filter` table。

一般与防火墙规则相关的会放在 filter table 中，我们可以使用 `iptables --table filter --list` 列出所有的 filter 表，表中记录就是端口和 ip 的过滤规则，比如：

```
Chain INPUT (policy DROP)
target prot opt source destination
ACCEPT udp -- 192.168.1.0/24 anywhere multiport dports 1:65535
```

这条规则表示允许 `192.168.1.0/24` 子网内的所有设备使用 **任意 UDP 端口** 访问 **任何目标地址**，没有任何限制。

`nftables` 可以理解为是 `iptables` 的继任者，旨在提供更现代化和高效的数据包过滤框架。与 `iptables` 相比，`nftables` 引入了更简洁的语法和更强大的功能，支持事务型规则更新和更好的性能。在 Ubuntu 官方日志中 21.10 已经默认使用 `nftables`，但你可能会发现 `iptables` 指令仍然可以使用，这是因为 Ubuntu 使用的是 `iptable` 的 `nf_tables` 模式，这个模式下允许 `iptables` 使用 `nftables` 的 API，属于一种过渡性的方案（实际背后仍然是 `nftable`，你可以使用 `ls -l /usr/sbin/iptables-nft` 来验证这一点）。但是比较旧的 Ubuntu 仍运行的是 `legacy` 模式，你可以使用 `iptables -v` 来检查当前使用那种模式。

### ufw

虽然 `iptables`、`nftables` 已经将 `netfilter` 封装了一层，但是规则设定仍然很复杂，对于非专业 Linux 运维人员来说，只想简单的设置哪些端口、哪些 IP 需要禁用掉就可以了，怎么书写 `iptables` 规则什么的根本不想学。`ufw` 就是一个可以极度简化 `iptables`、`nftables` 配置的工具。

只需要简单的学习如下几个指令即可轻松使用 ufw：

- `ufw status`：查看 ufw 状态、配置了哪些规则；
- `ufw allow 80`：允许 80 端口号开放（tcp 和 udp）；
- `ufw allow 22/tcp`：允许所有的外部IP访问本机的22/tcp (ssh)端口；
- `ufw allow from 192.168.1.100`：允许此IP访问所有的本机端口；
- `ufw deny smtp`：禁止外部访问 smtp 服务；
- `ufw enable`：启用 ufw；
- `ufw disable`：禁用 ufw；

或者更简单的，可以使用 1Panel 的防火墙管理功能，来可视化的配置 ufw。

## 2.2 使用 fail2ban 或 sshguard

### fail2ban

fail2ban 是一款用于防御服务器被外部攻击的工具，它可以通过读取系统或应用的日志，并根据配置规则，与系统防火墙配合，主动禁止某些 IP 的连接。

安装：

```sh
apt install fail2ban
```

启用服务并设置守护进程：

```sh
systemctl start fail2ban
systemctl enable fail2ban
```

一般情况下这样就可以了，对于 ssh、mysql、nginx 这种常见的应用 fail2ban 已经配置好了响应的应用规则，如果 fail2ban 发现了日志中的异常，比如 ssh 在 60 秒内登录失败了 3 次，那么就会将这个 IP 写入到 iptables 的规则，知道 600 秒后再解除禁用。你可以使用 `sudo iptables -L -n | grep f2b` 来过滤出 fail2ban 创建的规则表，并找到哪些 IP 被禁用。

如果你希望修改配置规则，比如将封禁的 IP 永久拉黑，或者将规则写到 ufw 中而不是直接写到 iptables 中，你可以创建一个 `/etc/fail2ban/jail.local` 文件并写入如下配置：

```
[DEFAULT]
bantime = -1
findtime = 60
maxretry = 3
banaction = ufw
```

使用 `systemctl restart fail2ban` 即可重新生效。

上面的自定义配置代表如果在 60 秒内尝试失败 3 次，那么该 IP 的禁用时间就设置为 `-1` 表示永久禁封，`banaction` 代表封禁行为，ufw 表示使用 ufw 规则进行封禁，如果出现 IP 被封禁，我们可以使用 `ufw status` 就可以看到这些 IP：

```
To                         Action      From
--                         ------      ----
Anywhere                   REJECT      118.122.147.8             
Anywhere                   REJECT      14.103.121.78             
Anywhere                   REJECT      120.157.38.255            
Anywhere                   REJECT      80.94.95.112              
Anywhere                   REJECT      196.251.67.42  
```

你也可以使用 fail2ban 的命令行指令来查看 fail2ban 的状态：

- `fail2ban-client status`：查看 fail2ban 正在管理哪些应用；
- `fail2ban-client status sshd`：查看 ssh 的封禁状态；

### sshguard

sshguard 是一个更为轻量的、专门用于防止 ssh 密码暴力破解攻击的工具，如果你觉得 fail2ban 有很多功能不需要，可以尝试使用 sshguard。

安装：

```sh
apt install sshguard
```

启用服务并设置守护进程：

```sh
systemctl start sshguard
systemctl enable sshguard
```

在 `/etc/ufw/before.rules` 中写入：

```
# allow all on loopback
-A ufw-before-input -i lo -j ACCEPT
-A ufw-before-output -o lo -j ACCEPT

# hand off control for sshd to sshguard
:sshguard - [0:0]
-A ufw-before-input -p tcp --dport 22 -j sshguard
```

sshguard 的原理也是读取 ssh 的登录日志，然后为每个登录行为进行打分，如果分数达到一定阈值就会禁用这个 IP 的 ssh 连接请求，并且禁用时长会随着再次失败的尝试次数而逐渐递增。

你可以使用 `cat /var/log/auth.log | grep sshguard` 来查看 sshguard 的拦截记录：

```
Apr  1 16:03:39 cloud sshguard[2897]: Attack from "160.191.52.73" on service 100 with danger 10.
Apr  1 16:03:39 cloud sshguard[2897]: Attack from "160.191.52.73" on service 110 with danger 10.
Apr  1 16:03:40 cloud sshguard[2897]: Attack from "160.191.52.73" on service 110 with danger 10.
Apr  1 16:03:40 cloud sshguard[2897]: Blocking "160.191.52.73/32" for 120 secs (3 attacks in 1 secs, after 1 abuses over 1 secs.)
```

# 3. 引用参考

- https://arthurchiao.art/blog/deep-dive-into-iptables-and-netfilter-arch-zh/
- https://zhuanlan.zhihu.com/p/33546122
- https://www.51cto.com/article/707312.html