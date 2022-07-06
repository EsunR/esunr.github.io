---
title: Hexo + Obsidian + Git 完美的博客部署与编辑方案
tags:
  - Hexo
categories:
  - 其他
date: 2022-07-06 15:10:52
---

# 1. 前言

在之前的文章[《Hexo 快速搭建指南》](https://blog.esunr.xyz/2022/06/64163235c30f.html)中，重点讲解了如何搭建以及部署博客。但是在后期写博客的过程中，有可能遇到很多麻烦，比如：

- 我不想手动维护文章的 Categorys，我想以文件目录的形式管理文章分类
- VSCode 编写 Markdown 文件不爽，我想用其他的编辑器来写 Markdown
- `hexo new` 指令生成的模板太拉了，我不想用
- 我想把我的 markdown 文档同步到云平台上，方便我的其他设备即时查看

那么这篇文章就会教你使用最舒服的姿势来后期维护你的博客，减少心智负担与解决各种不爽的地方。

# 2. 更好的文章管理方案

## 2.1 文章以目录分类

当我们写好一篇文章后，按照 hexo 的默认配置，我们需要将其放在 `source/_post` 目录下，等时间长了之后，`_post` 目录下的文章就会变得杂乱无章，无法让我们快速的 review 到一篇文章。

那么最好的解决方案就是我们在创建文章的时候以 `文章分类` 作为文件夹创建我们的文章，比如：

```
.
└── source
    └── _post
        ├── 前端
        │   ├── Javascript
        │   │   └── Javascript原型链机制.md
        │   └── 浏览器
        │       └── 浏览器性能优化.md
        └── 后台
            ├── GoLang
            │   └── go语言简介.md
            └── Java
                └── Spring MVC 快速入门.md
```

## 2.2 根据文件目录自动生成 categories 信息

虽然我们把文章放的井井有条了，但是每个文章里的 `categorys` 字段还是要我们手动自己维护的，比如在 `source/_post/前端/Javascript/Javascript原型链机制.md` 文件中，我们要通过手写 `categories` 来让 hexo 知道这篇文章被放在 `前端-Javascript` 分类下：

```markdown
---
title: Javascript原型链机制
categories:
  - 前端
  - Javascript
date: 2022-06-05 12:06:47
---

这里是正文
```

为了省去手动维护 `categorys` 字段的这个问题，我们可以使用 [hexo-auto-category](hexo-auto-category) 这个插件。这个插件在 Hexo 进行 build 的时候会去自动根据文章目录情况来自动修改文章的 `categories` 信息，更详细的部分可以看[作者的文章](https://blog.eson.org/pub/e2f6e239/)。

除此之外最好修改一下 `_config.yml` 中的两处默认配置：

```yml
# 修改 permalink 让你的文章链接更加友好，并且有益于 SEO
permalink: :year/:month/:hash.html

# 规定你的新文章在 _post 目录下是以 cateory 
new_post_name: :category/:title
```

## 2.3 提交代码时自动生成新文章的 categories

但是这里有一个问题，就是只有 hexo 在执行 `hexo generate` 或者 `hexo server` 时候才会去触发 `categories` 的生成，那么每次我们创建文章都要经历这样的工作流：

1. 创建分类目录，写文章（不用关心 `categories` 写什么）；
2. 执行 `npx hexo generate` 在构建博客的时候触发 `hexo-auto-category` 插件的自动矫正 `categories` 功能；
3. 检查文章中的 `categories` 是否正确；
4. 添加 git 工作区变更，并提交并推送代码到 github。

为了简化这些工作，我们可以使用 git hook，在我们每次执行 `commit` 前都自动运行 `npx hexo generate` 触发自动生成 `categories` 的行为，并将生成后的变更自动添加到本次提交中，然后一同 push 到 github 上去。这里可以使用 husky 来很方便的设置这样一个 git hook。

> GitHook 可以在执行代码的 commit、push、rebase 等阶段前触发，做一些前置行为，比如在每次提交代码时候执行一段 shell 脚本，来做一些代码检查或者通知 ci 等操作。
> 
> Husky 采用了更简单的一种方式，让管理 GitHook 更加现代化
> 
> 关于 Husky 的使用可以参考我之前的文章[《使用 husky 每次提交时进行代码检查》](https://blog.esunr.xyz/2022/05/d36522b1089c.html)

1. 安装 huksy：`npm install husky --save-dev`
2. 执行 huksy 初始化指令：`npx husky install`
3. 在 `package.json` 中的 `scripts` 中写入：`"prepare": "husky install"`
4. 在生成的 `.husky` 目录创建 `pre-commit` 文件（有的话就不用创建），并写入以下内容：

```sh
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

npx hexo generate && git add .
```