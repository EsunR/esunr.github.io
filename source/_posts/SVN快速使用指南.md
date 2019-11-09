---
title: SVN快速使用指南
date: 2019-11-09 16:34:44
tags: SVN
categories: Git
---
# 1.svn的安装

svn 需要安装 sliksvn 才能在命令行中使用 `svn` 指令

```sh
svn --version
```
# 2.svn服务指令

## 2.1 创建指令

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

### 2.2.1 将svn按指令方式启动​

**指令：**

```SH
svnserve -d -r [Path]
```
\-d 表示后台执行，\-r 标识版本根目录，服务器将会运行在 3690 端口

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
