---
title: Git常用操作整理
tags: []
categories:
  - Front
date: 2019-11-18 23:05:28
---
# 1. Git 基本原理

- 工作区：我们能看到的，用来写代码的区域
- 暂存区：临时存储用的
- 历史区：生成历史版本

![Git基本工作流程](http://img.cdn.esunr.xyz/markdown/20191118231730.png)

# 2. 基础指令

## 2.1 Git 配置

查看配置信息：

```sh
git config -l           # 查看配置信息
git config --global -l  # 查看全局配置
```

设置配置：

```sh
git config --global user.name 'username'
git config --global user.email 'email'
```

## 2.2 提交到暂存区

在本地编写完成代码后，把一些内容提交到暂存区

```sh
git add xxx   # 把某个文件提交到暂存区
git add .     # 把当前仓库中的所有最新修改的文件都提交到暂存区
git add -A    # 同上
```

## 2.3 查看当前文件状态

红色代表在工作区，绿色代表在暂存区，看不见东西证明所有修改信息都已提交到历史区

```sh
git status 
```

![演示示例](http://img.cdn.esunr.xyz/markdown/20191118233413.png)


## 2.4 提交到历史区

只能将暂存区中的代码提交到历史区：

```sh
git commit -m '描述信息'
```

查看历史信息：

```
git log     # 查看历史版本信息
git reflog  # 查看包含回滚信息的历史版本信息
```

从工作区提交到暂存区、从暂存区提交到历史区都是把内容复制一份传过去，文本域中仍存在这些信息。

> 在 vscode 中，更改后的代码在提交时可以自动进行暂存操作（add），无需再手动暂存。

# 3. 远程仓库

## 3.1 远程源

查看当前仓库远程源：

```sh
git remote -v
```

添加/删除远程源:

```sh
git remote add origin 'Git Origin'   
git remote remove origin 'Git Origin'   
```

## 3.2 拉取提交到远程源

拉取远程源：

```sh
git pull origin master
```

提交远程源：

```sh
git push origin master
```