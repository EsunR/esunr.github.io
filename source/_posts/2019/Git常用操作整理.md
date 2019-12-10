---
title: Git常用操作整理
tags: [Github, Git]
categories:
  - Git
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
git config --local  -l  # 查看当前项目配置
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

## 3.4 Clone

Clone 可以简化拉取远程项目的步骤，与 `add remote origin` 并 `git pull` 不同的是，Clone 拉取的是整个项目的所有分支：

```sh
git clone 'Git Origin' 
```

## 3.5 https 免密码同步

在添加 git remote 地址的时候，如果使用的是 https，则需要每次提交同步代码的时候都输入用户名与密码，为了免去用户名与密码的输入我们可以修改 `.git/config` 文件下的配置，添加用户名与密码：

```diff
## config

[remote "origin"]
-      url = https://github.com/UserName/YourProject.git
+      url = https://username:password@github.com/UserName/YourProject.git
```

# 4. 内容处理

## 4.1 丢弃更改

当文件进行变更后，且尚未进入暂存区时，使用 `chekcout --` 指令可以丢弃已有的更改

```sh
git checkout -- <file>
```

## 4.2 撤销暂存

当更改过的文件被提交到暂存区后，可以重新撤回到工作区

```sh
git reset HEAD <file>
```

## 4.3 文件修改

### 4.3.1 文件删除

删除一个被 git 追踪的文件：

```sh
git rm <file>
```

与使用系统指令直接删除不同的是，文件删除之后会出现在暂存区，可以从暂存区中撤销到工作区，也可以再从工作区撤销更改，文件就会被恢复。


### 4.3.2 文件重命名

```sh
git mv <file name> <new file name>
```

此时文件会被存放到暂存区，显示为对文件进行了一个 R（rename） 操作

## 4.4 修改已提交的信息

当用户写错了一个提交信息并向修正信息时可以使用以下指令修正信息：

```sh
git commit --amend -m '纠正过的提交信息'
```

> amend: 修正

## 4.5 .gitignore

- `*.a` 忽略所有 .a 结尾的文件
- `!lib.a` 在上述的忽略规则中 lib.a 除外
- `/TODO` 仅仅忽略项目根目录下的 TODO 文件，不包括 subdir/TODO
- `build/` 忽略 build/ 目录下的所有文件
- `doc/*.txt` 会忽略 doc/notes.txt 但不包括 doc/server/arch.txt

# 5. 分支

## 5.1 分支查看

查看当前版本库的所有分支：

```sh
git branch
```

![](http://img.cdn.esunr.xyz/markdown/20191210112942.png)

## 5.2 创建分支

```sh
git branch <branch name>
```

