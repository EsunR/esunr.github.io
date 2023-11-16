---
title: 【万字拆解】Element Plus 组件库构建方案
date: 2023-11-16 18:56:44
tags:
  - Vue
  - Element-Plus
  - 前端工程化
  - 源码解析
---
# 1. 代码结构
## 1.2 目录分析

我们先聚焦项目的根目录，看些各个文件都有什么作用：

- `github` Github Action 相关的代码
- `.husky` husky 配置，详见[代码lint](## 代码lint)
- `brekings`
- `docs` 使用 vitepress 开发的组件文档
- `internal` 代码构建工具
- `packages` monorepo 子包
- `play` 提供一个本地调试组件的环境
- `scripts` 构建脚本
- `ssr-testing` 测试组件 SSR 环境的表现
- `typings` TypeScript 类型声明文件

## 1.3 包管理方案

### 好多 packages.json !

在分析目录的过程中，我们会发现在整个项目中并非只有一个 `package.json` 文件。在根目录会有一个 `package.json`，但是在 `play` 和 `docs` 下也有 `package.json`，尤其是在 `packages` 目录下的文件夹，每个文件都有一个独立的 `package.json`。

这是因为在 ElementPlus 中，由于其是一个比较庞大的应用，作者没有使用传统的前端项目管理方式去管理，而是将整个项目划分了不同的模块：

比如 docs 模块是负责开发组件库文档的，这个文件夹就相当于一个独立于 ElementPlus 的项目，那么 docs 模块就应该有其自己的 `package.json` 来管理 vite、vitepress、vue 这些开发组件文档所需要的依赖。

同理，play 模块也可以看做是一个独立的项目，其只是配置了一个单独的 Vue 环境来供开发人员调试组件代码，并不属于 ElementPlus 的源码，同时也会用到一些调试组件使用的 npm 包，因此也得有一个自己的 `package.json`。

### monorepo ?

按照上面的思路，我们可以将组件库的组件源码、样式源码、构建工具、utils 等这些可以解耦的模块都作为一个独立的项目去开发，然而 ElementPlus 的团队显然没有这么做（否则我们就会看到 ElementPlus 项目中可能会有很多代码库 `(repo)` 了）。而是将 ElementPlus 这个庞大的项目拆分成多个子模块后，都放在一个总的项目代码仓库(repo)里来管理，这种 **一个代码仓库(repo)里面管理多个项目** 的方式就叫作 monorepo。

如果不按照这种方式，而是使用多个代码仓库(git repo)管理，其面临着如下的问题：

- 开发人员需要同时修改多个子模块的代码库，不利于项目整体的版本管理和发布；
- 虽然一个大项目可以拆成多个子项目，但子项目之间还是有关联的，比如组件模块的代码需要引用到 utils 模块或者是样式模块的代码，使用多个仓库来管理可能需要 `git submodule` 这比较种复杂的方案才能处理；
- 模块之间的代码共享会很难，比如共享同一套 ESLint 配置，如果配置做了修改，所有的子模块都要同步修改；
- 庞大的 node_modules；

###  pnpm ? 

经过上面的对比，显然 monorepo 更适合 ElementPlus 的场景。在前端开发中使用 monorepo 的一个比较好的实践就是 pnpm。

pnpm 是一个与 npm、yarn 平级的前端包管理工具。但不同于 npm 和 yarn，pnpm 提供了很多 monorepo 工作流所需要的功能，比如：

- pnpm 采用软连接的方式将一个项目中相同的 npm package 放到项目的根目录一个公共的位置管理，在 monorepo 场景下可以大量减少 node_modules 的占用；
- 在根目录执行 install 指令时，pnpm 会同时并行安装子包中的依赖；

# 2. 组件开发

## 代码 lint

## 组件规范

## 样式处理

# 3. 构建方案

# 4. 其他

