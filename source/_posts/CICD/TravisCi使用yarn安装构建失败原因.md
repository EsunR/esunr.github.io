---
title: Travis Ci 出现 "eval yarn --frozen-lockfile" 构建失败解决方法
tags: []
categories:
  - CICD
date: 2020-03-10 23:41:45
---

# 1. 起因

在使用 Travis Ci 构建 Hexo 时在 2020 年 2 月份时出现了构件失败的情况，报错信息为 :

```
error Your lockfile needs to be updated, but yarn was run with `--frozen-lockfile`.
info Visit https://yarnpkg.com/en/docs/cli/install for documentation about this command.

The command "eval yarn --frozen-lockfile " failed. Retrying, 2 of 3.
```

# 2. 分析

Travis Ci 构建 Nodejs 项目的时候，默认使用了 yarn 作为 npm 的替换安装方式。但是在 2020 年 2 月份之前，默认的安装指令为：

```
$ yarn
```

但是之后 Travis Ci 修改了默认的安装指令，将其更改为：

```
$ yarn --frozen-lockfile
```

报错的信息显示该指令出现错误，那么这句话是什么意思的，在 yarn 文档中有这么一段话：

> 如果需要可重现的依赖环境（比如在持续集成系统中），应该传入 --frozen-lockfile 标志。

要理解这句话，事情还要从 ~~一只蝙蝠~~ npm 的包版本控制说起。我们在安装 npm 包的时候，通常会运行 `npm install` 之后还会生成一个 `package-lock.json` 文件，与之对应的，如果我们使用的是 `yarn install` 会生成一个 `yarn-lock.json` 文件，他们的目的就是记录当前我们下载下来的所有依赖包的树形结构。

那么问题来了，`package.json` 也是记录依赖的版本的，那么为什么还要有 `package-lock.json` 呢，这是因为 `package.json` 只约束了一个大版本，如 `"hexo": "^4.0.0",` 意思是安装版本大于 `4.0.0` 小于 `5.0.0` 的 `hexo`。

在 ci 环境下，由于要百分百模拟我们本机的编译环境，所以在 ci 端安装依赖就不能那么随心所欲的使用 `package.json` 来安装依赖包了，必须使用 `package-lock.json` ，否则万一我们依赖的某个包的新版本出现了 bug ，那么就会出现在开发机上可以编译但是在 ci 环境下不能编译的情况。

再返会看 `yarn --frozen-lockfile` 指令，其意思就是锁定当前依赖包的版本号，其进行的操作就是按照 `yarn-lock.json` 去安装。但是当一个依赖包拥有新版本时，yarn 为了防止开发者一直使用老旧版本的依赖，就会报出警告，就像我们遇到的问题那样。

# 3. 解决方案

我们可以修改 `.travis.yml` 安装部分的脚本，来取消使用 `--frozen-lockfile` 指令：

```yml
install:
  - yarn
```

但是并不推荐这么做，所以最好还是手动更新 `lock` 文件，更近的方式就是使用 `npm install` 再次进行安装即可。
