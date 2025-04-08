---
title: Docker 网络的几种模式
tags: []
categories:
  - 后端
  - 服务器
date: 2025-04-03 17:23:38
---
# Macvlan

创建 macvlan 网络：

```sh
docker network create -d macvlan --subnet=192.168.123.0/24 --gateway=192.168.123.1 -o parent=enp1s0 enp1s0-macvlan
```
