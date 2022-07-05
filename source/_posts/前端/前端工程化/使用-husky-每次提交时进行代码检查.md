---
title: 使用 husky 每次提交时进行代码检查
tags: []
categories:
  - 前端
  - 前端工程化
date: 2022-05-31 16:33:25
---
# Husky 简述

了解 Husky 前就必须先了解一下 GitHook 是什么，GitHook 可以在执行代码的 commit、push、rebase 等阶段前触发，做一些前置行为，比如在每次提交代码时候执行一段 shell 脚本，来做一些代码检查或者通知 ci 等操作。

但是对于如何使用好 GitHook 可能会让很多人头疼，因为大多数人可能不知道如何去写 shell 脚本，亦或者是对 .git 文件内的内容一无所知。因此，Husky 采用了更简单的一种方式，让管理 GitHook 更加现代化，正如 husky 简介中所说的：

> Modern native Git hooks made easy

# 安装

首先需要使用 npm 安装 husky：

```sh
npm install husky --save-dev
```

安装成功之后需要调用 husky 指令来进行初始化：

```sh
npx husky install
```

你可以将 `husku install` 写入 package.json，方便其他人安装：

```sh
npm set-script prepare "husky install"
```

这时，项目根目录会生成一个 .husky 文件夹，其内容为：

```sh
.
└── .husky
    └── _
        ├── .gitignore
        └── husky.sh
```

之后我们就可以使用指令添加 hook 了，比如我想在每次 commit 前执行 `npm lint` 脚本，那么就可以使用如下指令添加该操作：

```sh
npx husky add .husky/pre-commit "npm run lint"
```

之后 husky 就会生成一个 `pre-commit` 的脚本文件在 `.husky` 文件夹下：

```sh
└── .husky
    ├── _
    │   ├── .gitignore
    │   └── husky.sh
    └── pre-commit
```

# 与 lint-staged 协同使用

[lint-staged](https://github.com/okonet/lint-staged) 是一个专门用于在提交代码前对代码进行风格约束的工具，他可以很好的与 husky、eslint、prettier 一起工作。

首先需要安装 lint-staged：

```sh
npm install lint-staged --save-dev
```

之后配置 eslint 与 prettier，这里不多赘述，再然后在 package.json 中添加 `lint-staged` 字段，并编写匹配规则与执行脚本，以下为示例：

```json
"lint-staged": {
	"*.{js,vue,ts}": "eslint --cache --fix",
	"*.--write": "prettier --write"
}
```

之后修改 `.husky/pre-commit` 中执行的指令：

```sh
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

npx lint-staged
```

之后每次提交时就会对要提交的代码进行代码风格检查。