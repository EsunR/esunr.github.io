---
title: macOS 下安装php指南
tags: []
categories:
  - 后端
  - PHP
date: 2021-09-07 17:14:06
---
# 1. 前言

macOS 自带 PHP，以 Big Sur 为例，自带 PHP7.3：

```shell
$ php --version
WARNING: PHP is not recommended
PHP is included in macOS for compatibility with legacy software.
Future versions of macOS will not include PHP.
PHP 7.3.24-(to be removed in future macOS) (cli) (built: Jun 17 2021 21:41:15) ( NTS )
Copyright (c) 1997-2018 The PHP Group
Zend Engine v3.3.24, Copyright (c) 1998-2018 Zend Technologies
```

但是在项目中，我们可能用到各种版本的 PHP，同时更重要的是，macOS 自带的 PHP 是一个阉割版本，比如 `php-cgi` 就不包含在里面。

如果我们想安装完整的 php，可以使用 brew 来进行安装。

# 2. 使用 brew 安装 php

## 1. 安装 brew

上 brew 官网，按照说明即可

## 2. 安装 php

安装最新版本：

```shell
$ brew install php
```

安装指定版本：

```shell
$ brew install php@7.4
```



## 3. 启动安装好的 php

安装完成后，会出现如下提示（以 7.4 举例）：

```shell
To enable PHP in Apache add the following to httpd.conf and restart Apache:
    LoadModule php7_module /usr/local/opt/php@7.4/lib/httpd/modules/libphp7.so

    <FilesMatch \.php$>
        SetHandler application/x-httpd-php
    </FilesMatch>

Finally, check DirectoryIndex includes index.php
    DirectoryIndex index.php index.html

The php.ini and php-fpm.ini file can be found in:
    /usr/local/etc/php/7.4/

php@7.4 is keg-only, which means it was not symlinked into /usr/local,
because this is an alternate version of another formula.

If you need to have php@7.4 first in your PATH, run:
  echo 'export PATH="/usr/local/opt/php@7.4/bin:$PATH"' >> ~/.zshrc
  echo 'export PATH="/usr/local/opt/php@7.4/sbin:$PATH"' >> ~/.zshrc

For compilers to find php@7.4 you may need to set:
  export LDFLAGS="-L/usr/local/opt/php@7.4/lib"
  export CPPFLAGS="-I/usr/local/opt/php@7.4/include"


To start php@7.4:
  brew services start php@7.4
Or, if you don't want/need a background service you can just run:
  /usr/local/opt/php@7.4/sbin/php-fpm --nodaemonize
```

按照提示，执行如下指令启动 php 服务：

```shell
$ brew services start php
```

我们还可以调用如下指令查看当前的服务运行情况：

```shell
$ brew services list
Name    Status  User Plist
php     stopped
php@7.4 stopped
```

如果要想停止服务：

```shell
$ brew services start php@7.4
```

## 4. 覆盖系统服务

我们安装并启动好了 php 之后，再次执行 `php --version` 会发现还是原来系统版本的 php，同时 php-cgi 服务同样也是没有的，我们需要将安装好的 php 替换掉系统自带的 php。

brew 提供了 `brew link` 指令来快捷帮我们进行服务替换：

```shell
$ brew link --overwrite --force php@7.4
Linking /usr/local/Cellar/php@7.4/7.4.23... 25 symlinks created.

If you need to have this software first in your PATH instead consider running:
  echo 'export PATH="/usr/local/opt/php@7.4/bin:$PATH"' >> ~/.zshrc
  echo 'export PATH="/usr/local/opt/php@7.4/sbin:$PATH"' >> ~/.zshrc
```

之后再执行 `php --version` 就可以得到我们的目标版本了。

如果想要解除link，执行：

```shell
$ brew unlink php@7.4
```

