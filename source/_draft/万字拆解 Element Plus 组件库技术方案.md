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
- `.husky` husky 配置
- `brekings`
- `docs` 使用 vitepress 开发的组件文档
- `internal` 组件库构建代码
- `packages` monorepo 子包
	- `components` 组件源码
	- `constants` 存放一些常量的声明
	- `directives` 注册 vue 指令
	- `element-plus` 入口文件
	- `hooks` vue hook
	- `locale` 国际化语言包
	- `test-utils` 单测使用的 utils
	- `theme-chalk` 组件样式
	- `utils` 组件库使用的 utils
- `play` 提供一个本地调试组件的环境
- `scripts` 构建脚本
- `ssr-testing` 测试组件 SSR 环境的表现
- `typings` TypeScript 类型声明文件

## 1.3 包管理方案

> 省流小助手：ElementPlus 并不使用 npm 来管理依赖包，而是使用 pnpm 来管理，如果你清楚什么是 pnpm 以及 monorepo 的相关概念，可以跳过该章节。

### 好多 packages.json !

在分析目录的过程中，我们会发现在整个项目中并非只有一个 `package.json` 文件。在根目录会有一个 `package.json`，但是在 `play` 和 `docs` 下也有 `package.json`，尤其是在 `packages` 目录下的文件夹，每个文件都有一个独立的 `package.json`。

这是因为在 ElementPlus 中，由于其是一个比较庞大的应用，作者没有使用传统的前端项目管理方式去管理，而是将整个项目划分了不同的模块：

比如 docs 模块是负责开发组件库文档的，这个文件夹就相当于一个独立于 ElementPlus 的项目，那么 docs 模块就应该有其自己的 `package.json` 来管理 vite、vitepress、vue 这些开发组件文档所需要的依赖。

同理，play 模块也可以看做是一个独立的项目，其只是配置了一个单独的 Vue 环境来供开发人员调试组件代码，并不属于 ElementPlus 的源码，同时也会用到一些调试组件使用的 npm 包，因此也得有一个自己的 `package.json`。

### monorepo

按照上面的思路，我们可以将组件库的组件代码、样式代码、构建代码、utils 等这些可以解耦的模块都作为一个独立的项目去开发，存放到多个代码仓库(git repo)中管理。然而 ElementPlus 并没有这么做（否则我们就会看到 ElementPlus 有很多代码仓库了），因为如果将一个项目拆成多个代码库管理就会存在下面的问题：

- 开发人员需要同时修改多个子模块的代码库，不利于项目整体的版本管理和发布；
- 虽然一个大项目可以拆成多个子项目，但子项目之间还是有关联的，比如组件模块的代码需要引用到 utils 模块或者是样式模块的代码，如果拆成多个代码库，代码之间的互相依赖很难处理；
- 模块之间的代码共享会很难，比如共享同一套 ESLint 配置，如果配置做了修改，所有的子模块都要同步修改；
- 每个项目都要去维护 package.json 文件，还会有庞大的 node_modules；

> 其实 git 拥有一个 submodule 功能专门用来处理多个 git 仓库之间互相依赖、引用的问题，但是还是很麻烦，并且同步多个子库的代码会很痛苦。

ElementPlus 将各个独立的模块进行了划分后，仍然将多个子模块放在同一个代码库(repo)管理，来规避多个代码库管理复杂和无法共享代码的问题，这种 **一个代码仓库(repo)里面管理多个项目** 的方式就叫作 monorepo。
### pnpm

ElementPlus 并非只是简单的采用文件夹的方式对子模块进行划分，这样的话整个项目只是一个大号文件夹而已，并没有解决代码共享、模块引用这些问题。这时候就需要采用一个工具来完善 monorepo 这样的工作流，ElementPlus 团队选择使用了 pnpm，项目根目录的 `pnpm.lock` `pnpm-workspace.yaml` 文件就是 pnpm 的相关文件。

pnpm 是一个与 npm、yarn 平级的前端包管理工具。但不同于 npm 和 yarn，pnpm 提供了很多 monorepo 工作流所需要的功能，比如：

- pnpm 采用软连接的方式将一个项目中相同的 npm package 放到项目的根目录一个公共的位置管理，在 monorepo 场景下可以大量减少 node_modules 的占用；
- 在根目录执行 install 指令时，pnpm 会同时并行安装子包中的依赖；
- pnpm 支持 workspace 协议（yarn 和 npm 7.x 也支持），将子项目作为 workspace 加入到主项目中后，各个子项目之间就可以通过 workspace 协议，像引入一个 npm 包一样互相引用，这就解决了如 "组件模块相关的代码需要引入 utils 模块的代码" 这样的问题。

### workspace

pnpm 引入了一个非常重要的功能，那就是 workspace 协议。`pnpm-workspace.yaml` 文件声明了哪些目录可以作为子包处理，这些子包都有自己的 package.json 文件，里面会声明子包的 package name（通常子包都会使用命名空间，比如 ElementPlus 的所有子包都在 `@element-plus/xxx` 这个命名空间下），有些子包还有自己独有的一些依赖。

在根目录的 `package.json` 中，你还可以看到部分被注册为 workspace 的子包也会被作为项目依赖安装了，其版本号均为 `workspace:*`，如：

```
"@element-plus/utils": "workspace:*",
"@element-plus/hooks": "workspace:*",
"@element-plus/directives": "workspace:*",
```

这样不同的 workspace 子包就可以互相引用了，比如你经常可以在组件代码中看到：

```ts
import { addUnit, getScrollContainer, throwError } from '@element-plus/utils'
import { useNamespace } from '@element-plus/hooks'
```

这些以 `@element-plus` 开头的 npm 包并非来自 npm，而是来自 workspace 协议，举例来说：

`@element-plus/utils` 实际上是在引用根目录的 `node_modules/@element-plus/utils`，而该目录又是由 workspace 创建的一个软链接，链接到了 `packages/utils` 目录。因此引用 `@element-plus/utils` 就是在引用 `packages/utils` 目录下的代码。

这样就很优雅的实现了子包之间的代码引用，本质上非常像调试 npm 包时候使用的 `npm link` 指令，但是 pnpm 的 workspace 让这一切都变得更简单化。

好了，现在已经解释清楚了 ElementPlus 的包管理方案以及为什么要使用 pnpm 了，你可以使用 pnpm 来为源码安装好依赖继续愉快的玩耍了。

# 2. 组件开发

## 代码 lint

## 组件规范

## 样式处理

# 3. 构建方案

# 4. 其他

