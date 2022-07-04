---
title: 世界上最好的语言 Linux 环境下安装与启用扩展指南
tags:
  - php
categories:
  - 后端
  - PHP
date: 2019-12-19 16:54:50
---

# 1. 薛定谔的 PHP

当你使用一台 Linux 设备时，你永远不知道你的设备上被安装了多少个 PHP 的版本，也不会知道当前的 PHP 设置是什么，关于 PHP 的多版本管理与信息查看可以查看 [这篇文章的末尾](https://blog.esunr.xyz/2019/12/PHP%E5%BC%80%E5%8F%91%E7%8E%AF%E5%A2%83%E6%90%AD%E5%BB%BA%E6%8C%87%E5%BC%95/)。只有你搞明白了 PHP 的版本如何管理你才能顺滑的安装 PHP 的各种插件。

**踩坑预警：** 如果你的插件没有生效，请依次检查

1. 在 `php.ini` 中是否启用该插件；
2. 当前环境（命令行 or Apache）下的 `php.ini` 目录；
3. 扩展的路径（extension_dir）；
4. `php7.x-dev` 安装的版本是否是当前环境的版本；
5. 重新审视所有的操作与你自己的人生。

以下所有流程都建立于 **当前环境下仅安装了一个 PHP 版本，并且假定 PHP 版本为 7.3** ，以安装一个 `phpredis` 插件为示例演示。

# 2. 下载 phpredis 源码

打开 `phpredis` 的[版本发布地址](https://github.com/phpredis/phpredis)，获取最新版本的 `tar.gz` 格式的下载链接：

```
https://github.com/phpredis/phpredis/archive/5.1.1.tar.gz
```

移动到一个你能找到的目录下，如 `/usr/src` ，运行：

```sh
$ wget https://github.com/phpredis/phpredis/archive/5.1.1.tar.gz
```

之后解压源码文件，并进入该目录：

```sh
$ tar xvzf phpredis-xxx.tar.gz
$ cd phpredis-xxx.tar.gz
```

# 3. 安装 phpredis

[官方安装文档](https://github.com/phpredis/phpredis/blob/develop/INSTALL.markdown)

下载下来的源码还未经过编译，官方文档提供了简单的三步走策略：

```sh
$ phpize
$ ./configure [--enable-redis-igbinary] [--enable-redis-msgpack] [--enable-redis-lzf [--with-liblzf[=DIR]]] [--enable-redis-zstd]
$ make && make install
```

我们一步步看，如果运行 `phpize` 错误，我们就需要安装当前 php 的 dev 版本才能获取到编译工具，**安装的版本必须为当前PHP环境的版本**，以 php7.3 为例：

```sh
$ apt-get install php7.3-dev
```

之后再运行：

```sh
$ phpize
```

等待完成后，需要再执行 `./configure` ，这条指令后面可以加一个参数 `--with-php-config` ，代表当前的 php 环境参数，你可以通过该参数向多个 php 版本中安装插件，如果你的设备上只有一个，你可以加载该参数也可以不加载该参数：

```sh
$ ./configure --with-php-config=/usr/bin/php-config
```

接下来就可以直接执行编译与安装:

```sh
$ make && make install
```

# 4. 启用插件

打开 `php.ini` 文件（以 Apache 环境下的 PHP 配置为例）：

```sh
$ vim /etc/php/7.3/apache/php.ini
```

向配置文件中添加该扩展的信息：

```
; php.ini
extension=redis
```

重启 Apache 服务器：

```sh
apachectl restart
```

之后使用 `phpinfo()` 方法即可查看当前 php 的环境，如果可以搜索到 `redis`，那么就说明安装完成。

如果启用无效，请回头看标题1。