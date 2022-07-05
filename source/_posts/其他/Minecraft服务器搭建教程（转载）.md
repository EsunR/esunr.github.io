---
title: Minecraft服务器搭建教程（转载）
tags: []
categories:
  - 其他
date: 2020-01-26 14:14:42
---
没想到新站搭好这么久没写东西，第一篇居然是这水货。本来没什么好写的，但是官网上说明简直太少了，坑死人，写这篇白话教程就当顺便吐槽吧。

### 安装

> 官方服务端下载页面：[https://minecraft.net/zh\-hans/download/server/bedrock/](https://minecraft.net/zh-hans/download/server/bedrock/)
>
> 直链：
>
> Windows：[https://minecraft.azureedge.net/bin\-win/bedrock\-server\-1.8.0.24.zip](https://minecraft.azureedge.net/bin-win/bedrock-server-1.8.0.24.zip)
>
> Linux：[https://minecraft.azureedge.net/bin\-linux/bedrock\-server\-1.8.0.24.zip](https://minecraft.azureedge.net/bin-linux/bedrock-server-1.8.0.24.zip)
>
> 内容来自Minecraft官网

##### Linux：

官方提供的服务端仅仅支持新版（测试18.04 LTS 正常）的Ubuntu服务器（其他发行版到现在为止试了这么多没一个跑起来的，，，打包的时候都不考虑一下兼容性么），注意国内大量云服务厂商包括阿里云在内都提供的是16.04版本的Ubuntu，如果直接安装将无法运行。

以阿里云为例，购买时选择安装Ubuntu 16.04 LTS 的系统镜像，登陆后执行：

```
sudo apt-get install update-manager-core
sudo do-release-upgrade

```

然后注意跟随屏幕上的提示进行更新，所有的包都要选择更新，否则套件版本过低会导致服务端程序无法运行（再次吐槽什么辣鸡兼容性）。更新过程根据服务器性能不同会进行几分钟到几十分钟不等，期间会经常需要确认，不能点了更新就跑。

更新完成以后就直接下载安装。首先新建个文件夹并进入：

```
mkdir mc
cd ./mc

```

下载并解压服务端程序：

```
wget https://minecraft.azureedge.net/bin-win/bedrock-server-1.8.0.24.zip
unzip bedrock-server-1.8.0.24.zip

```

如果第二条命令没法执行就需要安装一下：

```
sudo apt-get install unzip

```

解压好以后可以用ls查看一下文件，只要多出来一大堆文件应该就没问题了。这时候安装已经完成了，但是还需要进一步的配置才能运行。

##### Windows：

Windows就不细说了，下载下来点开就行。我在我的Windows 10 上可以正常运行但是Win server 2012 （R2，貌似）上怎么折腾也不行，能安装的环境都安装了，缺的dll也补齐了，但是依旧报无法运行。跑起来的大佬可以解释一下什么鬼情况。反正接续吐槽辣鸡兼容性就对了。**教程的后半部分也不会继续再说Windows，所有操作都是在Linux上进行的。**在Windows上运行的话类比即可。

### 配置服务端软件

首先编辑server.properties（vi是Linux上常用的一个文本编辑工具，不会用的话自行百度，也就几个常用命令就能学会，再在这里教vi的话，，，你想累死我啊233333）。下面有文件的内容，~一些重要或者常用的部分~我用中文加了注释（好吧，一不小心都加了中文注释）（英文注释是最详细的）：

```
vi server.properties

```

#server.properties：
server\-name=Dedicated Server
\# 服务器名称
\# Used as the server name
\# Allowed values: Any string

gamemode=survival
\# 游戏模式（生存/创造/冒险）
\# Sets the game mode for new players.
\# Allowed values: “survival”, “creative”, or “adventure”

difficulty=easy
\# 难度
\# Sets the difficulty of the world.
\# Allowed values: “peaceful”, “easy”, “normal”, or “hard”

allow\-cheats=false
\# 是否允许作弊
\# If true then cheats like commands can be used.
\# Allowed values: “true” or “false”

max\-players=10
\# 最大玩家数
\# The maximum number of players that can play on the server.
\# Allowed values: Any positive integer

online\-mode=true
\# 是否在线验证（验证Xbox账号，要是不存在网络问题就开着吧）
\# If true then all connected players must be authenticated to Xbox Live.
\# Clients connecting to remote (non\-LAN) servers will always require Xbox Live authentication regardless of this setting.
\# If the server accepts connections from the Internet, then it’s highly recommended to enable online\-mode.
\# Allowed values: “true” or “false”

white\-list=false
\# 是否开启白名单
\# If true then all connected players must be listed in the separate whitelist.json file.
\# Allowed values: “true” or “false”

server\-port=19132
\# IPv4 端口，没特殊情况默认就好
\# Which IPv4 port the server should listen to.
\# Allowed values: Integers in the range \[1, 65535\]

server\-portv6=19133
\# IPv6 端口，没特殊情况默认就好
\# Which IPv6 port the server should listen to.
\# Allowed values: Integers in the range \[1, 65535\]

view\-distance=32
\# 视野大小（区块）（开太大会加重服务器开销）
\# The maximum allowed view distance in number of chunks.
\# Allowed values: Any positive integer.

tick\-distance=4
\# 玩家附近加载区块范围（只有加载区块里面的实体/电路/植物等等会被刷新）（一样，开多了会卡）
\# The world will be ticked this many chunks away from any player.
\# Allowed values: Integers in the range \[4, 12\]

player\-idle\-timeout=30
\# 超时时间（超过这个时间不操作的玩家会被踢掉），单位是分钟。
\# After a player has idled for this many minutes they will be kicked. If set to 0 then players can idle indefinitely.
\# Allowed values: Any non\-negative integer.

max\-threads=8
\# 最大线程
\# Maximum number of threads the server will try to use. If set to 0 or removed then it will use as many as possible.
\# Allowed values: Any positive integer.

level\-name=Bedrock level
\# 世界名称
\# Allowed values: Any string

level\-seed=
\# 世界种子
\# Use to randomize the world
\# Allowed values: Any string

default\-player\-permission\-level=member
\# 默认权限
\# Permission level for new players joining for the first time.
\# Allowed values: “visitor”, “member”, “operator”

texturepack\-required=false
\# 强制加载材质包
\# Force clients to use texture packs in the current world
\# Allowed values: “true” or “false”

配置好以后保存（:wq），然后就可以启动服务器试试啦：

```
LD_LIBRARY_PATH=. ./bedrock_server

```

```
NO LOG FILE! - setting up server logging...
NO LOG FILE! - [2018-12-27 13:18:58 INFO] Starting Server
NO LOG FILE! - [2018-12-27 13:18:58 INFO] Version 1.8.0.24
[2018-12-27 13:18:58 INFO] Level Name: mc
[2018-12-27 13:18:58 INFO] Game mode: 0 Survival
[2018-12-27 13:18:58 INFO] Difficulty: 1 EASY
[2018-12-27 13:19:00 INFO] IPv4 supported, port: 19132
[2018-12-27 13:19:00 INFO] IPv6 supported, port: 19133
[2018-12-27 13:19:00 INFO] Server started.
```

如果出现类似上面的输出就说明软件可以正常运行了。运行命令也可以保存到一个.sh文件里面，方便以后使用（先stop掉服务器）：

```
vi start.sh
#在文本编辑界面插入：LD_LIBRARY_PATH=. ./bedrock_server
#然后保存退出（:wq）
chmod 0777 start.sh

```

以后打开服务器就可以直接./start.sh了。

### 配置防火墙

大部分服务器都默认关闭这些端口，所以成功运行了服务端你还是连不上。以阿里云为例，首先要在服务器管理页面上开启端口，以轻量应用服务器为例，在安全\->防火墙里面打开相应端口（之前在配置文件里设置的那两个）。建议为了方便打开全部端口（1/65535）的TCP+UDP，让服务器内部的防火墙进行管理（当然你也可以全都打开然后不管，不过这不是给好习惯）。

新版本Ubuntu上，使用的是ufw，设置非常简单：

```
ufw allow 22
# 允许你的SSH端口，不然开启以后ssh就连不上了(如果不是22记得改掉)
ufw allow 19132
ufw allow 19133
# 允许Minecraft使用的端口，如果你更改了配置文件，这里和你配置文件保持一致。
ufw enable
# 开启防火墙

```

现在运行服务器，试试从你的电脑上连接服务器吧。

### 在后台运行

之前那样运行的服务端，如果关掉ssh连接窗口，服务端软件也会退出。这里我们使用screen命令来实现后台运行。与其他方式相比，screen能让你更方便的与服务端进行交互：

```
sudo apt-get install screen
# 很多电脑上没有安装screen，先进行安装。
screen -R mc
# 新建一个叫mc的窗口并进入
cd ./mc
./start.sh
# 运行服务端，没有做./start.sh就直接运行 LD_LIBRARY_PATH=. ./bedrock_server

```

这样服务端就能在后台运行了，如果想同时在服务器上干其他事情，可以使用快捷键”ctr+A D”“最小化”当前窗口。在窗口被最小化或者重新登陆服务器后，可以通过”screen \-r mc”恢复窗口进行交互。

### 其他问题

0：这是基岩版的服务端，不是网易代理的那玩意的！

1：如果在Win10版我的世界上连接本地（127.0.0.1）服务器，需要解除回环：

```
# 在powershell（管理员模式）中执行下面的命令
CheckNetIsolation.exe LoopbackExempt –a –p=S-1-15-2-1958404141-86561845-1752920682-3514627264-368642714-62675701-733520436

```

2：基本命令

op <玩家名称>
\# 赋予管理员权限
stop
\# 停止服务器
reload
\# 重新加载（热重启）
kick <玩家名>
\# 踢出服务器
save <hold/query/resume>
\# 备份,懒得写了，看官方给的说明吧，不备份的话用处不大
\# hold：This will ask the server to prepare for a backup. It’s asynchronous and will return immediately.
\# query:After calling save hold you should call this command repeatedly to see if the preparation has finished. When it returns a success it will return a file list (with lengths for each file) of the files you need to copy. The server will not pause while this is happening, so some files can be modified while the backup is taking place. As long as you only copy the files in the given file list and truncate the copied files to the specified lengths, then the backup should be valid.
\# resume:When you’re finished with copying the files you should call this to tell the server that it’s okay to remove old files again.