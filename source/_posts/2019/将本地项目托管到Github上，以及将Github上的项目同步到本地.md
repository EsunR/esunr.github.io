---
title: 将本地项目托管到Github上，以及将Github上的项目同步到本地
tags: [Github, Git]
categories:
  - Git
date: 2018-12-21 21:50:06
---
## 前言
在日常开发中我们经常会遇到这样的需求：在本地开发项目同步到Github上，同时将服务器上的代码也做更新。倘若能把 `本地-Github-服务器` 这三个平台关联（如图），这样就能极大的提高我们的效率。

![代码走向](https://img-blog.csdnimg.cn/20181216172049924.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3UwMTI5MjU4MzM=,size_16,color_FFFFFF,t_70)

那么大体上的思路就只分两步了：
1. 将本地项目托管到Github
2. 将Github上的代码同步到远程服务器端

# 本地项目托管到Github
先假设我们再本地的D盘目录下创建了一个`test`文件夹，里面放着我们的项目代码，接下来我们需要进行如下操作将其托管到Github。

### 1. 本地下载安装Git环境
这一步不多做赘述，去Git官网下载Git的安装包就可以了，安装完成后打开`Git Bash`应用，输入指令：
```
$ ssh-keygen -t rsa -C "yourEmail"
$ Generating public/private rsa key pair.
$ Enter file in which to save the key (/c/Users/esunr/.ssh/id_rsa): 
$ Created directory '/c/Users/esunr/.ssh'.
$ Enter passphrase (empty for no passphrase):
$ Enter same passphrase again:

$ git config --global user.name "yourName"
$ git config --global user.email "yourEmal"
```
`yourName`和`yourEmal`分别对应你的Github用户名和邮箱

### 2. 添加开发机的SSH Key
`SSH Key`即SSH公钥，只有我们把某台PC的SSH公钥添加到Github的设置中，我们的这台PC才能跟我们上传的项目进行同步和更改。

首先我们打开Git Bash，在命令中输入
```
$ cd ~/.ssh
$ ls
```
如果列出如下目录：
```
id_rsa  id_rsa.pub  known_hosts
```
说明已存在SSH Key无需再生成，如果不存在则运行
```
$ ssh-keygen
```
生成`id_rsa.pub`文件后，我们使用命令查看密钥
```
$ cat id_rsa.pub
```
得到的密钥大概长这样
![](https://img-blog.csdnimg.cn/20181216175220282.png)
我们将`id_ras.pub`文件中的所有文本都复制下来，打开Github，选择右上角头像-Settings-SSH and GPG keys，点击选项面板中的`New SSH Key`。
![](https://img-blog.csdnimg.cn/20181216175625434.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3UwMTI5MjU4MzM=,size_16,color_FFFFFF,t_70)
将自己的SSH Key添加到选项中即可，之后我们可以运行测试是否连接到Github
```
ssh -T git@github.com
```
如果出现如下提示，则说名连接成功
```
Hi EsunR! You've successfully authenticated, but GitHub does not provide shell access.
```
### 3. 在Github中创建空项目
我们点击右上角的“+”选择`New repository`创建一个新项目，要注意一点的是：
> 新项目中除了题目和描述之外，不要点击任何选项，我们要的是一个完全空的项目仓库

![在这里插入图片描述](https://img-blog.csdnimg.cn/20181216180209540.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3UwMTI5MjU4MzM=,size_16,color_FFFFFF,t_70)

### 4. 上传本地项目代码到Github
我们点击`Create repository`之后，会出现一个提示，如下做讲解
```
// 这一步是跳转到本地的项目目录，我们可以替换为cd指令跳转，cd C:/test
echo "# test" >> README.md
// 初始化项目
git init
// 添加一个README.md文件（选择性）
git add README.md
// 托管更改
git add . 
// 提交一次初始化更改
git commit -m "first commit"
// 将本地与Github做远程连接
git remote add origin git@github.com:EsunR/test.git
// 提交代码到主分支
git push -u origin master
```
之后再刷新Github页面就发现代码提交完成了。

# Github代码同步到服务器
> PS: 将代码下载到本地同理

### 1. 服务器下载安装Git环境
与上文相同，只不过是服务器端就不需要用Git Bash了

### 2. 添加开发机的SSH Key
与上文相同

### 4. 同步项目代码到服务器（本地）
首先在服务器或本地创建一个文件夹，作为项目的存放仓库，利用cd指令跳转到该文件夹下，如：
```
$ cd /var/www/html
$ mkdir test
$ cd test
```
初始化该目录为Git仓库
```
$ git init
```
我们在Github中打开我们的项目，之后选择`Clone or download`，复制我们项目的SSH地址
![在这里插入图片描述](https://img-blog.csdnimg.cn/20181216182538392.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3UwMTI5MjU4MzM=,size_16,color_FFFFFF,t_70)
将仓库远程源连接到Github上的该项目
```
$ git remote add origin git@github.com:EsunR/test.git
```

> PS: 如过手滑信息填写错误，使用清除指令 `$ git remote remove origin` 清除源


使用`Pull`指令，从远程源的主分支更新代码到服务器（本地）
```
$ git pull origin master
```
完成。
