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
git log         # 查看历史版本信息
git reflog      # 查看包含回滚信息的历史版本信息
git log --graph # 以时间线的形式查看分支信息
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

查看各分支最近一次提交的记录：

```sh
git branch -v
```

## 5.2 创建分支

```sh
git branch <branch name>
git checkout -b <branch name> # 创建并切换到新分支
```

## 5.3 切换分支

git 分支的切换也用的是 `checkout` 指令，这与文件的签出要进行区别，文件的签出是将文件从工作区撤销更改，而分支的签出是改变分支：

```sh
git checkout <branch name>
git checkout - # 切换到上一个分支
```

## 5.4 删除分支

git 不可以删除当前分支，删除分支前需要切换到别的分支：

```sh
git branch -d <branch name>
```

如果删除的目标分支被改动且没有被合并过，则分支需要使用强制删除：

```sh
git branch -D <branch name>
```

## 5.5 分支合并

```sh
git merge <target branch> <branch>  # 将 branch 的最新修改合并到 target branch 中
git merge <branch>                  # 将 branch 的最新修改合并到当前分支
```

如果将某一个分支（branch）的最新修改合并到目标分支（target branch）上，那么目标分支（target branch）的文件会处于修改的最新版本，而合并的分支（branch）并不会拥有目标分支（target branch）的新内容。如果需要目标分支（target branch）的新内容，则需要将目标分支合并到该分支上。

## 5.6 HEAD 与 master

HEAD 指的是当前分支，master 指的是当前提交的版本：

![](http://img.cdn.esunr.xyz/markdown/20191210141717.png)

当用户新创建了一个 dev 分支，最新的分支还是会指向当前 master 主分支指向的节点：

![](http://img.cdn.esunr.xyz/markdown/20191210142013.png)

当用户在 dev 分支进行提交后，dev 分支会新建一个版本并指向新版本的提交：

![](http://img.cdn.esunr.xyz/markdown/20191210142110.png)

当 master 分支上没有进行更改，此时合并 dev 与 master 分支的话，master 分支的指针会直接指向当前的版本，我们称这样的操作为 “快进（fast forward）”：

![](http://img.cdn.esunr.xyz/markdown/20191210142312.png)


## 5.7 冲突解决

当我们将 dev 分支的最新内容合并到 master 分支时如果出现了冲突需要手动解决冲突，冲突的文件会内容会被标识为类似：

```
new file
<<<<<<< HEAD
master edit
=======
dev edit
>>>>>>> dev
```

此时我们需要手动进入到文件中，将不需要的代码删除，然后再进行一次提交，这样就解决了冲突。

当此时切回到 dev 分支后，如果想要获取到最新的 master 分支的内容，则需要将 master 分支合并到 dev 分支，此时由于 master 分支被标记为最新更改，所以如果在 dev 分支上没有对已在 master 分支解决了冲突的文件进行修改，dev 分支就会直接快进到 master 分支的版本。

实际上冲突也是另外开了一个冲突分支，我们解决冲突就是去合并冲突分支：

![](http://img.cdn.esunr.xyz/markdown/20191210152834.png)

## 5.8 fast-forward

如果可能，git 提交会使用 fast-forward 模式，在这种模式下合并分支并未生成一个新的提交，而是将当前分支的指针指向了