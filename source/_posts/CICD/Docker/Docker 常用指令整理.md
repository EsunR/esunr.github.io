---
title: Docker 常用指令整理
tags:
  - Docker
  - 常用指令
categories:
  - CICD
  - Docker
date: 2022-11-16 10:48:49
---
# 1. 查看信息

## 1.1 查看版本

```shell
docker version
```

## 1.2 查看系统信息

```shell
docker info
```

# 2. Container

## 2.1 创建 container

docker 会先去查找本地 nginx 镜像，如果查找不到就会从远程下载

```shell
docker container run [image name]
```

将 container 内部的端口号映射到外部：

```shell
docker container run -p [实体机端口]:[docker 内端口] [image name]

// eg:
docker container run -p 80:80 nginx
```

后台 (detached) 模式创建 container： ^3c04af

```shell
docker container run -d [image name]

// eg:
docker container run -d -p 80:80 nginx
```

[[3. docker container run 背后发生了什么]]

## 2.2 查看 container

```shell
docker container ls
```

![](https://i.loli.net/2021/10/26/cU1SKVl5g2O7bPF.png)

可以使用旧版本指令：

```shell
docker container ps
docker ps
```

`ls` 与 `ps` 指令只能查看运行中的容器，如果想要查看所有容器，需要后缀参数 `-a`：

```shell
docker contianer ls -a
```

列出所有的 container id（包含运行中和未运行的）

```shell
docker container ls -qa
```

## 2.3 停止 container

> windows 下必须手动停止，macos 在终端中结束后就自动停止

```shell
docker container stop nginx
docker contianer stop [container id] // 使用 id 停止 docker（可以只用前两位）
```

批量停止：

```shell
docker container stop $(docker container ps -qa)
```

## 2.4 重启 container

```shell
docker container restart [docker id]
```

## 2.5 删除 container

```shell
docker container rm [contianer id]
```

批量删除：

```shell
docker container rm $(docker container ps -qa)
```

强制删除：

```shell
docker container rm [container id] -f
```

## 2.6 在前台查看 container

使用 [`-d`](#^3c04af) 指令创建的 container 如果想要在前台查看，可以使用指令：

```shell
docker attach [contianer id]
```

此时在前台查看 container 时如果在 UNIX 系统环境下，`ctrl+c` 会直接退出 container。

## 2.7 查看 container 的日志

```shell
docker container logs [container id]
docker container logs -f [container id] // 实时打印
```

## 2.8 交互式运行 container

在启动时进入交互式模式中：

```shell
docker container run -it ubuntu sh // 会打开 Ubuntu 的 shell，并且可以交互
```

以交互式的方式进入正在运行的 container 中【常用功能】：

```shell
docker exec -it [container id] sh
```

> 如果以交互式模式启动一个 container，执行 `exit` 退出时会停掉整个容器，但是以交互式方式进入正在运行中的容器并退出时，并不会退出当前的容器。

## 2.9 查看 container 中的进程

```shell
docker container top [cotnainer id]
```

# 3. Image

## 3.1 获取镜像

```shell
docker image pull [registry] # 从 registry 拉取
docker image build from [Dockerfile] # 从 Dockerfile 构建
docker image load form [file] # 文件导入（离线）
```

## 3.2 查看已有的镜像

```shell
docker image ls
```

## 3.3 查看镜像详细信息

```shell
docker image inspect [image id]
```

## 3.4 删除镜像

```shell
docker image rm [image id]
```

> 如果镜像被容器使用中，镜像是无法删除的
