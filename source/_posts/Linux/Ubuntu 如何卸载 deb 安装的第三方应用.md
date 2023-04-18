---
title: Ubuntu 如何卸载 deb 安装的第三方应用
tags:
  - Linux
  - Ubuntu
categories:
  - Linux
date: 2023-04-18 11:30:27
---

如果你是在 Ubuntu 应用商店中安装的应用，可以通过查看『已安装』面板进行卸载，但是假如你使用 `.deb` 文件安装了第三方应用，是无法通过应用商店进行写在的，这时就需要通过指令卸载。

首先通过 `dpkg` 命令列出你已经安装的应用，可以使用 `grep` 指令进行过滤：

```sh
dpkg --list | grep app_name
```

之后可以在终端中使用 `dpkg -r` 来卸载该应用程序：

```sh
dpkg -r app_name
```