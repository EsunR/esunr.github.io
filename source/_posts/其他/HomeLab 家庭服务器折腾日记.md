---
title: HomeLab 家庭服务器折腾日记
tags:
  - Linux
  - 网络原理
categories:
  - 其他
date: 2025-04-08 14:08:27
---
# 1. 网络结构安排

家庭中有一台 N100 小主机，平常只用来跑一个 Ubuntu 太浪费了，为了榨干主机性能于是打算使用 PVE 做一个 All in one 小主机，覆盖家里所有的网络管理以及搭建一些应用的需求。

我的 N100 小主机有两个网络接口，因此可以一个做 WAN 口来接入运营商网络，一个做 LAN 口来提供家庭内部的网络，同时在 PVE 上安装一个 ikuai 软路由系统负责路由功能，又整了 n 台 CR 8806 路由器刷上集客 AP 的系统来组无线网络，整体的网络拓扑设计如下：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202504081501861.png)

光纤入户后接入光猫，光猫最好开启桥接模式，通过 WAN 口连接 N100 主机，内部的 iKuai 系统识别 WAN 口后进行拨号连接互联网，然后通过 vmbr 虚拟网桥将网络通向 PVE 内部的其他系统，以及物理 LAN 口。然后通过在物理 LAN 口接出一个交换器后，就可以将网络通向其他设备或者无线 AP。

N100 系统里安装了多个操作系统，iKuai 是用来做软路由的，Ubuntu 和 Windows 是主要使用的操作系统。此外我还加了一个没有桌面系统的 Ubuntu Server 来充当跳板机，内部安装了 FRP 内网传统服务，以及开放了 IPv6 访问，并做了 DDNS 动态域名绑定，来专门为外部提供网络访问。

# 2. PVE

### 系统安装

从官网安装：https://pve.proxmox.com/wiki/Downloads

烧录到 U 盘后，安装到 N100 主机中，这里不多描述了。

### 网络设置

在安装步骤中选择一个网卡，这张网卡对应的物理网口就是用来提供 LAN 口网络的，然后输入一个网关地址（这里的网关地址要作为后面我们安装 iKuai 的网关地址），并且输入一个管理地址，这里的网段要一致，比如网关地址为 192.168.100.1，那么管理地址应该为 192.168.100.x。

安装完成后将电脑网线接入到主机的 LAN 口，开始设置 PVE 系统。访问刚才设置的管理地址，进入管理页面，点击网络以后可以看到如下设备：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202504081517307.png)

enp1s0 和 enp2s0 都是物理网卡，对应主机的两个网口。vmbr0 是 PVE 内部的虚拟网桥，是桥接在 LAN 口的物理网卡上的，在创建虚拟机时网卡一般都会选择这个虚拟网桥，相当于操作系统使用网线接入了主机的 LAN 口网络。enp2s0 目前是空闲的状态，这个我们在安装 ikuai 的时候才会有用，需要将其作为 wan 口对应物理设备。

### 分区合并

默认的，pve 会创建两个分区，一个 local 分区用于存放用户上传的镜像和其他数据，一个 local-lvm 分区用于为虚拟机创建存储卷。但是对于一般或者磁盘比较小的用户来说，没有必要区分分区，两个分区可以合并为一个，并不影响使用：

删除 local-lvm分区：

```sh
lvremove pve/data
```

把 local-lvm空间合并给 local分区：

```sh
lvextend -rl +100%FREE pve/root
resize2fs /dev/mapper/pve-root
```

删除 local-lvm：网页登录，数据中心---存储---移除local-lvm分区

编辑 local，内容全选上，保存退出：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202504081538624.png)

### 上传系统镜像

下载好需要安装的镜像后，进入下图所示位置上传镜像，然后就可以创建虚拟机了。

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202504081545195.png)

# 3. iKuai

### 系统安装

为了简化 PVE 内部的网络管理，一般都会为其安装一个软路由系统来管理内部的网络，此外既然安装了软路由系统，就可以将其作为家庭网络的入口来进行拨号上网，就像上面的网络结构中，光猫的下游设备就是我们的小主机。

简单理解来说，N100 主机就相当于一个没有无线功能的主路由器，iKuai 就是为这个路由器来提供操作系统的，至于家庭中的无线路由器，只是作为这个主路由器的子路由接入到家庭网络中的。

按正常流程创建 iKuai 虚拟机，网络仍选择 vmbr0，进入虚拟机后此时应该只能看到一个网络接口，将其绑定为 LAN 口后并选择设置 LAN/WAN 地址，将 LAN 口地址设置为我们创建 PVE 时填写的网关地址 192.168.100.1。

然后进入 PVE 虚拟机的硬件管理中，点击添加 - PCI 设备：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202504081551348.png)

选择原始设备并选中另外一张我们要用作 WAN 口的网卡（也就是我们在安装 PVE 时没有选择到的那张空闲网卡，一般编号 01 对应 enp1s0，编号 02 对应enp2s0）：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202504081552618.png)

这里的操作是将空闲的网卡直通给了 iKuai 系统，然后进入 iKuai 系统后，查看一下桥接的网卡是否被正常识别并自动绑定为 WAN 口，如果没有的话要手动在“设置网卡绑定”选项中手动绑定一下：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202504081602410.png)

然后进入 iKuai 的管理页面（LAN 口的地址），可以看到 LAN 口和 WAN 口正常工作了：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202504081603527.png)

然后就是常规的路由器设置，将光猫连接 WAN 口，设置网络拨号、开启 DHCP，注意将 DHCP 分配的网段要设置的跟 iKuai 和 PVE 管理地址的网段一致。

### 开启 IPv6

在 IPv6 设置中添加或者启用 IPv6 外网配置：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202504081607214.png)

选择 DHCPv6 动态获取后，如果光猫支持，就会从上游获取到运营商分配的 IPv6 地址、网关、前缀、DNS 信息，如果失败的话需要将光猫改为桥接模式。

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202504081608157.png)
为了给内网下发 IPv6 地址前缀，还需要配置对应的内网接口，这里建议开启 DHCPv6，并使用无状态 + 有状态模式（有状态就是 DHCPv6 下发一个 IPv6 地址，无状态就是接入设备获取到 IPv6 前缀后自动生成一个后缀），DNS 服务器可以设置为上一步外网配置中运营商下发的 DNS：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202504081619326.png)

# 4. 跳板机

这里加入的跳板机其实是为了作为外部接入内部网络的入口，同时还提供了一个透明网关的功能，用于内部设备的科学上网。

### DDNS

通常服务商分配的 IPv6 前缀是动态的，因此设备的 IPv6 地址可能是会变化的，DDNS 服务就是时刻获取设备的 IPv6 地址，发生改变后就主动通知域名的服务商来修改域名绑定的地址，外部只需要访问域名就能稳定的访问到内部网络了。

这里推荐使用 DDNS GO 来搭建 DDNS 服务：https://github.com/jeessy2/ddns-go

这样我们内部就有了一个 IPv6 访问的入口了，我们可以从外网通过 ssh 等服务来接入内网服务。配合 iKuai 的防火墙功能，我们可以只开放跳板机的 IPv6 网络访问，就能控制外部的网络入口了。当然这就也要求跳板机的安全行足够高，可以配合防火墙 + fail2ban + 2FA 认证来进一步加固跳板机的访问权限，具体可以参考我的这篇文章：[《使用防火墙与 fail2ban 防止公网服务器被攻击》](https://blog.esunr.site/2025/04/387549224301.html#fail2ban)。
