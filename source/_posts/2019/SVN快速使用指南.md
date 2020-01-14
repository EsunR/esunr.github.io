---
title: SVN快速使用指南
tags: [SVN, 快速使用]
categories:
  - Git
date: 2019-08-06 16:34:44
---

# 0. svn 概念

SVN 基础概念：

*   **repository（源代码库）**：源代码统一存放的地方
*   **checkout（提取）**：当你手上没有源代码的时候，你需要从 repository checkout 一份
*   **commit（提交）**：当你已经修改了代码，你就需要 commit 到 repository
*   **update（更新）**：当你已经 checkout 了一份源代码，update 一下你就可以和 repository 上的源代码同步，你手上的代码就会有最新的变更

SVN 生命周期：

*   **创建版本库**：create 操作创建一个新的版本库，版本库用于存放文件，包括了每次修改的历史。
*   **检出**：checkout 操作从版本库创建一个工作副本，作为开发者私人的工作空间，可以进行内容的修改，然后提交到版本库中。
*   **更新**：update 操作更新版本库，将工作副本与版本库进行同步。因为版本库是整个团队共用的，当其他人提交了改动，你的工作副本就会过期。
*   **执行变更**：检出之后，可以进行添加、编辑、删除、重命名、移动文件/目录等变更操作。当最终执行了 commit 操作后，就对版本库进行了相应变更。
*   **复查变化**：当你对工作副本进行了一些修改后，你的工作副本就会比版本库新，在 commit 操作之前使用 status/diff 操作复查下你的修改是一个好的习惯。
*   **修复错误**：如果你对工作副本做了许多修改，当时不想要这些修改了，revert 操作可以重置工作副本的修改，恢复到原始状态。
*   **解决冲突**：合并的时候可能发生冲突，使用 merge 操作进行合并。因为 SVN 合并是以行为单位的，只要不是修改的同一行，SVN 都会自动合并，如果是同一行，SVN 会提示冲突，需要手动进行确认修改，合并代码。其中 resolve 操作可以帮助找出冲突。
*   **提交更改**：将文件/目录添加到待变更列表，使用 commit 操作将更改从工作副本更新到版本库，提交是添加注释说明，是个好的习惯。

# 1.svn的安装

svn 需要安装 sliksvn 才能在命令行中使用 `svn` 指令

```sh
svn --version
```

# 2.svn服务指令

## 2.1 创建指令

创建指令是创建出一个 SVN 项目服务端的源代码仓库，用来记录当前项目的版本信息，同时也为了记录一些权限相关的配置信息。（注意：每一个项目都要有一个单独的源代码仓库）

**​指令：**

```sh
svnadmin create [Path]
```
**创建出的目录：**

* conf/        设置权限时，需要设置conf目录
* db/            存储svn自身的数据
* hooks/    存放钩子，在每次提交时可以触发一定时间
* locks/
* format
* README\.txt

## 2.2 启动服务器端程序

在创建了一个 SVN 项目服务端的源代码仓库后，服务器端可以通过 `svnserve` 来启动当前的 SVN 服务，提供给客户端进行连接。

### 2.2.1 将svn按指令方式启动​

**指令：**

```SH
svnserve -d -r [Path]
```
\-d 表示后台执行，\-r 标识版本根目录，服务器将会运行在 3690 端口

启动的方式有两种，一种为 **直接指定到版本库（单库模式）** 还有一种为 **指定到版本库的上级目录（多库模式）**，这两种模式的区别在于访问时是否需要提供项目名为路由作为区分。举个例子，当我们在服务器端创建一个 `svn` 目录，用于做 SVN 的项目仓库存储，然后我们将要使用 SVN 管理两个项目，一个项目名为 OA 一个项目名为 SHOP，因此我们在 `svn` 目录下创建了 `OA` 与  `SHOP` 目录，如下：

```
svn
|- OA
|- SHOP
```

成功创建之后，我们分别使用 `svnadmin` 指令创建仓库：

```sh
svnadmin create ./svn/OA
svnadmin create ./svn/SAHOP
```

之后我们要使用 `svnserve` 指令运行 svn 服务，但是指定不同的 Path 会开启不同的模式，如我们运行：

```sh
svnserve -d -r ./svn/OA
```

那么此时运行的就是单库模式，我们直接访问 `svn checkout svn://localhost` 就可以访问到 OA 项目的 SVN 服务，但是此时没有办法访问到 SHOP 的 SVN 服务。

> svn checkout 指令可以拉取服务端代码

但是如果我们运行：

```sh
svnserve -d -r ./svn
```

那么此时运行的就是多库模式，我们需要访问 `svn checkout svn://localhost/OA` 才可以访问到 OA 项目的 SVN 服务，但是使用 `svn checkout svn://localhost/SHOP` 可以访问到 SHOP 项目的服务了。

### 2.2.2 将svn作为系统服务器启动（可后台运行）

```sh
sc create SVNService binpath= "C:\Program Files\SlikSvn\bin\svnserve.exe --service -r D:\SvnRep" start= auto depend= Tcpip
```
PS：这些指令的等号左边没空格，等号右边有一个空格

# 3.svn操作指令

## 3.1 取出版本（检出）

创建两个工作空间，选择其中一个工作空间，然后检出服务器的项目

```sh
cd ./DevWorkSpace/WorkSpaceSvn
mkdir SpaceJerry
mkdir SpaceTom
cd SpaceJerry
svn checkout svn://localhost/OA

>取出版本0
```
## 3.2 提交指令

### 设置权限

在服务器端存放的项目地址下，打开 `conf/svnserve.conf` 文件，并进行权限编辑，将匿名写入权限开启：

```
anon-access = write # 将匿名访问开启
# auth-access = write
```
### 提交版本

```sh
# 新创建一个文件
vi text.txt
# 将文件加入版本控制系统
svn add text.txt
# 填写日志信息并提交
svn commit -m "My first commit" text.txt
```
### 更新指令

当服务器上的代码发生了变动，可以使用如下指令对本地项目进行升级：

```sh
svn update
```
# 4.解决冲突

## 4.1 冲突产生的前置条件

Jerry 与 Tom 同时更新到项目的 9.0 版本后开始工作；

当 Jerry 完成工作后提交项目，此时项目升级到了 10.0；

Tom 仍在 9.0 版本工作，当 Tom 的工作完成后进行提交时，会显示当前版本**已过时。**



​这时，我们需要先更新版本再提交，但是当 svn 的 diff 算法检查出新的代码与当前已更改的代码发生了冲突，svn 就会产生提交冲突。

## 4.2 冲突产生的文件

* \*.main  是自己的文件
* \*.rx         x代表了在x版本时代码的状态

# 4.权限

## 4.1 开启授权访问

打开 \`conf/svnserve.conf\` 文件，关闭匿名访问，开启授权访问

```
anon-access = none    # 必须将匿名访问设置为none，否则提交历史将不可见
auth-access = write   # 开启授权访问
password-db = passwd  # 存放密码文件
authz-db = authz      # 存放授权信息的文件
```
## 4.2 设置用户

打开 \`conf/passwd\` 文件，设置用户名与密码

```
[users]
tom = 123456
jerry = 123456
ceshi = 123456
```
## 4.3 设置权限

打开 \`conf/authz\` 文件，对用户进行分组：

```
[groups]
kaifa = tom,jerry
```
分组后可以对在该组的用户集体进行读写权限设置，设置的方式为对文件路径设置权限：

```
# 设置权限目录
[/]
# 为用户组设置读写权限
@kaifa = rw
# 为单个用户设置读权限
ceshi = r
# 设置 * 可以做到权限屏蔽，除了以上的用户，其余用户均没有读写权限权限
* = 
```
