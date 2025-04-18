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

### 透明网关

参考：[《使用 Mihomo(Clash) 搭建透明网关，使局域网设备科学上网》](https://blog.esunr.site/2025/04/ec8dc9f7a09d.html)

### 端口转发

内网转发的意义在于，你可以通过 DDNS 绑定跳板机的 IPv6 地址，然后从跳板机上进行端口转发，从而访问局域网其他设备的服务，这样也有助于在公网限制开放的端口数量，从而提升安全性。

可以使用 [lucky](https://github.com/gdy666/lucky) 面板可视化的配置内网转发。

比如 PVE 的 win10 虚拟机开启了 3389 端口，那么就可以开放一个跳板机 13389 的端口，映射到 win10 主机 IP 上的 3389 端口，映射的目标 IP 也可以使用内网 IPv4。

# 5. 硬件直通

在虚拟机的环境下，一般是通过桥接或者虚拟化来连接物理设备的，但是在这种情况下部分硬件是不能够很好的发挥作用的，比如你想利用显卡硬解视频、HDMI 输出画面，那么就需要将这些硬件设备直通给虚拟机使用，这个过程就叫做硬件直通。

### windows 单显卡直通

> 该方式不借助 sriov 虚拟化，是直接将显卡 PCI 直通给了 windows 系统，其他虚拟机无法共用。原版教程：[https://www.right.com.cn/forum/thread-8413927-1-1.html](https://www.right.com.cn/forum/thread-8413927-1-1.html)

PVE 启动内核IOMMU支持：

```sh
#修改引导内核
vim /etc/default/grub

# 修改内容
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt pcie_acs_override=downstream"
```

更新 GRUB 配置  

```sh
update-grub
```

屏蔽驱动：

```sh
vim /etc/modprobe.d/pve-blacklist.conf  

# 添加内容
# block INTEL driver  
blacklist i915  
blacklist snd_hda_intel  
blacklist snd_hda_codec_hdmi  
  
#允许不安全的设备中断  
options vfio_iommu_type1 allow_unsafe_interrupts=1
```

更新 initramfs 并重启：  

```sh
update-initramfs -u -k all  
reboot
```

增加 module：

```sh
vim /etc/modules 

# 添加内容
vfio  
vfio_iommu_type1  
vfio_pci  
vfio_virqfd  

#新版PVE8.3自动增加的  
coretemp
```

将设备加入进 vfio：

```sh
# 查看设备 ID
lspci -D -nnk | grep VGA
0000:00:02.0 VGA compatible controller [0300]: Intel Corporation Alder Lake-N [UHD Graphics] [8086:46d1]

# id就是：8086:46d1，在你的PVE上运行，看得到的id是多少，因为下面vfio.conf修改为你自己的id。
```

```sh
vim /etc/modprobe.d/vfio.conf  

# 输入内容，将 id 替换为上面查询的 ID
options vfio-pci ids=8086:46d1
```

下载 N100 vbios（用于让虚拟机识别显卡硬件）：[https://github.com/gangqizai/igd/tree/main](https://github.com/gangqizai/igd/tree/main)，将 `gen12_gop.rom` 和 `gen12_igd.rom` 复制到 `/use/share/kvm/` 目录下。

手动修改你的wind10虚拟机参数，只看重点部分是否相同：

```sh
# 100 替换为虚拟机的 ID
vim /etc/pve/qemu-server/100.conf  

# 核对一下内容
agent: 1  
  
#重点，作用是设置虚拟机与hostpci直通添加下面一行。  
args: -set device.hostpci0.addr=02.0 -set device.hostpci0.x-igd-gms=0x2 -set device.hostpci0.x-igd-opregion=on  
  
#重点，BIOS选“OVMF(UEFI)”，不能选SeaBIOS  
bios: ovmf  
boot: order=scsi0;ide0;net0  
cores: 3  
  
#重点，处理器选“host”  
cpu: host  
  
#重点，直通显卡BIOS加载  
hostpci0: 0000:00:02.0,legacy-igd=1,romfile=gen12_igd.rom
  
#重点，直通显卡自带的HDMI声卡，不然HDMI接电视没有声音
hostpci1: 0000:00:1f.3
  
ide0: none,media=cdrom  
  
#机型选“pc-i440fx-8.0”  
machine: pc-i440fx-8.0  
  
#新版PVE8.3“pc-i440fx-8.1”（不能选q35）  
#machine: pc-i440fx-8.1  
  
memory: 16384  
meta: creation-qemu=8.1.5,ctime=1719398459  
name: win10-ip56  
net0: virtio=BC:24:11:4B:FF:CE,bridge=vmbr0  
numa: 0  
onboot: 1  
ostype: win10  
scsi0: local-lvm:vm-100-disk-1,iothread=1,size=200G,ssd=1  
scsihw: virtio-scsi-single  
smbios1: uuid=97a88487-8081-4213-923f-34fc4756a37b  
sockets: 1  
startup: order=30  
unused0: local-lvm:vm-100-disk-0  
usb0: host=3-4  
#AX211 USB蓝牙直通  
usb1: host=8087:0033  
usb2: host=3-1.4  
usb3: host=24ae:1008  
usb4: host=4-3  
usb5: host=062a:4101  
usb6: host=4-4  
usb7: host=3-5  
usb8: host=2-2  
usb9: host=3-1  
#重点，关闭虚拟VGA显卡，用intel直通显卡显示。  
vga: none  
vmgenid: 959ded06-690b-41c4-bbbb-8d4bcc5dfa09
```

进入 windows 后前往 intel 官网下载处理器对应的显卡驱动，比如 N100 可以使用：[https://www.intel.cn/content/www/cn/zh/download/785597/intel-arc-iris-xe-graphics-windows.html?wapkw=n100](https://www.intel.cn/content/www/cn/zh/download/785597/intel-arc-iris-xe-graphics-windows.html?wapkw=n100)



