---
title: node应用服务器部署与多版本管理指南
tags:
  - node
  - pm2
  - nvm
categories:
  - 后端
  - Node
date: 2020-01-30 23:29:56
---

# 1. 使用 n 与 nvm 管理 node 版本

## 1.1 n

n 是一个需要全局安装的 npm package。

这意味着，我们在使用 n 管理 node 版本前，首先需要一个 node 环境。我们或者用 Homebrew 来安装一个 node，或者从官网下载 pkg 来安装，总之我们得先自己装一个 node —— n 本身是没法给你装的。

然后我们可以使用 n 来安装不同版本的 node。

在安装的时候，n 会先将指定版本的 node 存储下来，然后将其复制到我们熟知的路径 `/usr/local/bin`，非常简单明了。当然由于 n 会操作到非用户目录，所以需要加 `sudo` 来执行命令。

所以这样看来，n 在其实现上是一个非常易理解的方案。

> 引用：https://fed.taobao.org/blog/taofed/do71ct/nvm-or-n/?spm=taofed.homepage.header.7.7eab5ac8a3p43I

安装：

```sh
$ npm install -g n
```

下载完成后就可以使用 `n` 来安装指定版本的 node：

```sh
$ n 版本号
```

下载最新版本：

```sh
$ n latest
```

删除某个版本：

```sh
$ n rm 4.4.4
```

查看当前 node 版本：

```sh
$ node -v
```

切换版本：

```sh
$ n

  6.9.4
ο 7.4.0
  4.4.4
```

以指定的版本来执行脚本：

```sh
$ n use 7.4.0 index.js
```

获取某个 node 版本的 bin 文件目录：

```sh
$ n bin 8.17.0
```

## 1.2 nvm

不同于 n，nvm 不是一个 npm package，而是一个独立软件包。

我们可以使用 nvm 来安装不同版本的 node。

在安装的时候，nvm 将不同的 node 版本存储到 `~/.nvm/<version>/` 下，然后修改 `$PATH`，将指定版本的 node 路径加入，这样我们调用的 `node` 命令即是使用指定版本的 node。

nvm 显然比 n 要复杂一些，但是另一方面，由于它是一个独立软件包，因此它和 node 之间的关系看上去更合乎逻辑：nvm 不依赖 node 环境，是 node 依赖 nvm；而不像 n 那样产生类似循环依赖的问题。

同时由于 nvm 是通过修改系统 PATH 来切换全局的 node 版本，因此如果系统使用了 nvm 来管理 node 版本，n 的管理就会失效。

nvm 基础指令：

```sh
$ nvm -h //查看nvm的指令
$ nvm list //查看本地已经安装的node版本列表
$ nvm list available //查看可以安装的node版本
$ nvm install latest //安装最新版本的node
$ nvm install [version][arch] //安装指定版本的node 例如：nvm install 10.16.3 安装node v10.16.3 arch表示电脑的位数 如果电脑需要安装32位的， 则运行：nvm install 10.16.3 32
$ nvm use [version] //使用node 例如：nvm use 10.16.3
$ nvm uninstall [version] //卸载node
```

`nvm use` 仅能指定当前的 node 版本，并不能将其指定为默认的 node 版本，可以通过以下方法设置默认的 node 版本：

```sh
nvm alias default v13.7.0
```

# 2. PM2 管理 node 应用

pm2（process manager）是一个进程管理工具，维护一个进程列表，可以用它来管理你的node进程，负责所有正在运行的进程，并查看node进程的状态，也支持性能监控，负载均衡等功能。

使用pm2管理的node程序的好处：

- 监听文件变化，自动重启程序
- 支持性能监控
- 负载均衡
- 程序崩溃自动重启
- 服务器重新启动时自动重新启动
- 自动化部署项目

## 2.1 PM2 基础使用

安装：

```sh
$ npm install pm2 -g 
```

启动一个node程序: 

```sh
pm2 start start.js --name test-app
```

查看运行列表：

```sh
pm2 list 
```

![](https://i.loli.net/2020/01/30/o8N1qWATgluyaE4.png)

删除进程:

```sh
// pm2 delete [appname] | id
pm2 delete app  // 指定进程名删除
pm2 delete 0    // 指定进程id删除
pm2 delete all
```

查看某个进程具体情况: 

```sh
$ pm2 describe app
```

查看进程的资源消耗情况: 

```sh
$ pm2 monit
```

重启进程：

```sh
$ pm2 restart app // 重启指定名称的进程
$ pm2 restart all // 重启所有进程
```

设置pm2开机自启：

开启启动设置，此处是CentOS系统，其他系统替换最后一个选项（可选项：ubuntu, centos, redhat, gentoo, systemd, darwin, amazon）

```sh
$ pm2 startup centos 
```

保存设置

```sh
pm2 save
```

## 2.2 PM2 指定不同的 node 版本

pm2 指令有一个选项为 `--interpreter` ，可以通过该选项指定 node 的位置，配合 n 模块的 `n bin [node-version]` 指令可以来获取不同版本 node 的路径：

```sh
pm2 -f start index.js --interpreter `n bin 8.17.0`
```