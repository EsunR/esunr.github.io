---
title: PHP 开发环境搭建指引
tags: [PHP, 快速使用]
categories:
  - Back
  - PHP
date: 2019-12-12 17:17:34
---

# 1. Apache

## 1.1 Windows 端安装 Apache

Windows 端安装 (Apache Haus)[https://www.apachehaus.com/cgi-bin/download.plx]，选择 x64 版本，下载完成之后是一个压缩包：

![](http://img.cdn.esunr.xyz/markdown/20191211161848.png)

将文件解压到任意一个工作目录，如：`D:/Apache24`，之后打开 Apache 目录下的 `/conf/httpd.conf` ，修改配置文件：

1. 初次修改必须要修改 `Define SRVROOT`，将其更改为我们解压后所放置的工作目录；
2. `Listen` 选项为服务的开启的端口，默认为 `80`，如果该端口被占用，需要改变端口号才可以启动 Apache 服务。

之后进入 `/bin` 目录下，使用有管理员权限的 `cmd` 或者 `powershell`，输入 `httpd.exe` 即可开启服务。


Windows 端的 apache 目录结构：

```
├─bin             # windows 可执行二进制文件
│  └─iconv
├─cgi-bin
├─conf            # 配置文件
│  ├─extra
│  ├─original
│  │  └─extra
│  └─ssl
├─error
│  └─include
├─htdocs          # 静态文件访问目录
├─icons
│  └─small
├─include
├─lib
├─logs
└─modules         # Apache 加载模块
```

之后可以将 Apache 安装为系统服务，那样便可以使用 `bin` 目录下的 `ApacheMonitor.exe` 工具，一键开启与重启 Apache 服务器（注意这里必须使用管理员权限运行命令行程序，并保证设置的端口没有被占用）：

```sh
httpd -k install
```

## 1.2 Apaceh 常用指令

查看模块状况：

```sh
httpd.exe -M

# <static> 为静态加载模块
# <shared> 为动态加载模块
```

验证配置文件：

```sh
httpd -t

# Syntax OK 表示没有错误
```

> Ubuntu 环境下需要使用 `apachectl` 替代 `httpd`

# 2. PHP

# 2.1 PHP 环境配置

上官网安装[适用于 Windows 的 PHP](https://windows.php.net/download)，**注意要下载 Thread Safe 版本，否则没有 Apache 的模块**。

下载同样是一个压缩包格式的文件，将其解压并放置到自定的目录，其目录结构为：

```
├─dev
├─ext                      # 扩展包
├─extras
│  └─ssl
├─lib
│  └─enchant
└─sasl2

- php.exe                  # 交互式解释器
- php.ini-development      # 开发版配置文件
- php.ini-production       # 生产环境下的配置文件
- php7apache2_4.dll        # apahce 支持文件
- php7apache2_4filter.dll  # apahce 支持文件
```

执行 php 文件：

```sh
php.exe -f /dirName/fileName.php
```

将 php 环境的目录设置到系统 PATH 中，即可直接编译运行 php 文件：

```php
// helloworld.php
<?php
  echo 'hello world'
?>
```

```sh
$ php helloword.php
> hello world
```

## 2.2 Apache 加载 PHP 模块

打开 Apache 配置文件，在 LoadModule 处添加模块路径：

```
# httpd.conf
LoadModule php7_module 'C:/Program Files/php/7.4.0/php7apache2_4.dll'
```

之后可以通过 `httpd -t` 来检查配置文件是否可用，同时使用 `httpd -M` 可以看到新增的模块：

```
php7_module (shared)
```

除此之外，我们还要显式配置 Apache 支持读取 php 文件：

```
# httpd.conf
AddType application/x-httpd-php .php
```

此时已可以将 php 文件放置到 `Apache24/htdocs/` 目录下，服务器即可处理 php 文件了。

## 3.3 Apache 加载 PHP 配置文件

由于 Apache 是运行 php 的环境，所以 php 的相关设置比如加载模块，需要让 Apache 读取，因此我们要让 Apache 去加载 PHP 的配置文件。

> 以下配置仅适用于 Windows 平台

在 Apache 配置文件中添加：

```
# httpd.conf
PHPIniDir 'C:/Program Files/php/7.4.0'
```

由于 PHP 环境下载下来之后，相关的配置文件并没有进行初始化操作，我们需要在 PHP 目录下创建一个 `php.ini` 文件，我们可以将 `php.ini-development` 复制一份并重命名为 `php.ini` 完成初始化操作。

之后我们可以在 apache 静态文件目录下（windows 平台在为 Apache 目录下的 htdocs 文件夹）中创建一个 `info.php`，输入：

```php
// info.php
<?php
phpinfo();
```

访问 `http://localhost/env.php` 既可看到当前的 php 环境配置详情：

![inof.php](http://img.cdn.esunr.xyz/markdown/20191219111739.png)

> php 的很大一个好处就是可以热更新，无需重启服务器修改文件即可生效，当然加载模块还是要重启服务器的。

## 3.4 PHP 选择加载模块

通过以上的设置，Apache 已经能够处理 PHP 文件了，但是 PHP 还有众多扩展包可以供我们使用，比如 `mysqli` 扩展可以帮助我们连接 myslq，只有我们启用了这些扩展，才可以在 PHP 中使用这些服务。

这里以启用 `myslqi` 扩展为例，打开 `php.ini` 文件，在 `;extension=mysqli` 这一行取消掉前面的 `;` 即启用该插件：

```
;php.ini
extension=mysqli
```

> 在 php7.3 以下版本，`mysqli` 可能被写为 `php_mysqli.dll`，这里也可以填写一个绝对路径来指向插件的存放位置。

在 Windows 平台上还需要额外配置 PHP 扩展的路径，如：

```
;php.ini
extension_dir = "C:/Progarm Files/php/7.4.0/ext/"
```

> Ubuntu 可以通过查看 phpinfo 来获取插件的默认路径。

# 3.5 设置 PHP 时区

系统默认的时区并不安全，需要手动切换为当前国家的时区：

```
date.timezone = RPC
```