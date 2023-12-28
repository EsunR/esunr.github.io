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

## 2.1 代码 lint

> 本章节不会详细介绍 lint 工具的使用，而是对 ElementPlus 中 lint 工具的使用方案进行拆解，如果你还不太了解前端 lint 工具的基础使用，可以参考这篇文章：[《前端 Lint 工具使用指南》](https://blog.esunr.site/2022/07/72bea7fe8c23.html)

### eslint

在根目录的 `.eslintrc.json` 配置中可以看到 ElementPlus 引入了一个 eslint 的扩展 `@element-plus/eslint-config`，这是一个项目的子包，实际上引用的是 `internal/eslint-config` 目录。该目录的 `index.js` 通过引用 `eslint-define-config` 这个 npm 包，创建了一套 eslint 配置，因此可以被 eslint 的配置文件所引用，ElementPlus 将总的 eslint 配置放在这里管理。

> `.eslintrc.json` 还配置了一个 `root: true` 这个配置在 monorepo 的项目中非常有用，可以让子包继承配置，意思是当前的 eslint 配置作为根配置，其他所有子包都从该配置的基础上进行应用或变更。
> 
> 如果有的子包需要在该规则上添加新的规则，则只需要在该子包的目录下创建一个新的 eslint 配置文件，该配置文件的内容就会与根配置文件的内容进行合并；如果不想让子包的 eslint 配置继承根配置文件中的规则，那么页只需要为子包中的 eslint 配置加上 `root: true` 的配置项即可。

我们来拆解一下它的 eslint 配置：

`plugins`插件，eslint 的插件提供了额外的校验功能，ElementPlus 装载了如下几个插件：

- @typescript-eslint：来自 `@typescript-eslint/eslint-plugin` TypeScript 的 eslint 插件，启用后才能配置各种 ts 的校验规则；
- prettier：来自 `eslint-plugin-prettier` 用于将 prettier 规则也作为 eslint 的校验条件，开启对应的规则后，如果代码不符合 prettier 的规范，eslint 会发出警告；
- unicorn：来自 `eslint-plugin-unicorn` 一个强大的 Eslint 规则集；

`extends` 继承，不同于插件，extends 可以继承一些 eslint 配置，这些配置我们可以从 npm 上下载，比如 `eslint-config-prettier` 就提供了一个配置，可以关闭 eslint 与 prettier 相冲的校验。一些 eslint 插件也提供了对应的配置，如果我们直接继承这些插件提供的 eslint 配置，就无需手动启用插件以及配置插件规则，ElementPlus 中继承了以下的几个规则集：

- eslint:recommended：eslint 的推荐配置；
- plugin:import/recommended：来自 `eslint-plugin-import`，用来规范模块的引入语法；
- plugin:jsonc/recommended-with-jsonc：来自 `eslint-plugin-jsonc`，用来规范 JSON 文件；
- plugin:markdown/recommended：来自 `eslint-plugin-markdown`，用来规范 markdown 文件；
- plugin:vue/vue3-recommended：来自 `eslint-plugin-vue`，用来规范 vue 文件；
- plugin:@typescript-eslint/recommended：来自 `@typescript-eslint/eslint-plugin`，用来规范 ts 文件；
- prettier：来自 `eslint-config-prettier`，用来与 `eslint-plugin-prettier` 相结合，开启 prettier 的校验，并关闭一些会与 eslint 冲突的配置。

`setting` 设置，这里用于设置一下 `eslint-plugin-import` 的作用范围。

`overrides` 覆写，通过 override 配置可以为某些文件单独配置一些 eslint 规则，有写插件如 `eslint-plugin-jsonc` 也需要使用该配置项指定某些文件需要使用该插件提供的解析器进行解析，是一个非常重要的配置项。

`rules` 规则，该配置项就是由项目的开发人员撰写，手动开启或关闭一些 eslint 或者是插件提供的配置，以供开发人员更加灵活的使用。

### commitlint

为了规范每次提交的 Commit Message，ElementPlus 使用了 commitlint 进行代码提交信息的 lint。commitlint 需要与 husky 结合使用，在 commit 行为发生之前进行 lint 校验，保证 commit message 的风格一致。更多关于 commitlint 相关的使用可以参考 [这里](https://blog.esunr.site/2022/07/72bea7fe8c23.html#3-CommitLint)，这一部分不再过多讲解。

## 2.2 组件开发

准备工作完成后，我们现在可以来拆解 ElementPlus 的组件源码了，以 Button 组件为例，我们看 ElemenPlus 是如何定义组件并将其暴露到外部的，以及组件如何在开发环境中进行调试。

### 组件入口

进入 `pacakges/components/button/index.ts` 文件，这就是 ElButton 的入口文件：

```ts
import { withInstall, withNoopInstall } from '@element-plus/utils'
import Button from './src/button.vue'
import ButtonGroup from './src/button-group.vue'

export const ElButton = withInstall(Button, {
  ButtonGroup,
})
export const ElButtonGroup = withNoopInstall(ButtonGroup)
export default ElButton

export * from './src/button'
export * from './src/constants'
export type { ButtonInstance, ButtonGroupInstance } from './src/instance'
```

一目了然的内容是，这个文件对外导出了 button.vue 和 button-group.vue 两个组件，然后由对外暴露了组建的一些常量、以及 types 声明。重点我们来看一下 `withInstall` 和 `withNoopInstall` 有什么用。

withInstall 方法中为组件挂载了一个 install 方法，这是为了将组件注册为一个 vue 插件，可以让 vue 使用 [app.use()](https://cn.vuejs.org/api/application.html#app-use) 方法挂载该插件，如当我们使用 `app.use(ElButton)` 时，我们可以在任意项目中使用 `el-button` 组件，这是因为该方法将组件注册为插件后，被 app 调用后就自动为全局注册了该组件。具体的代码逐行分析如下：

```ts
export const withInstall = <T, E extends Record<string, any>>(
  // 需要被注册为插件的组件
  main: T,
  // 该组件身上被挂载的组件，如 ElButtonGroup 可以被挂载为 ElButton.ButtonGroup
  extra?: E
) => {
  // SFCWithInstall 为 SFC 组件与 Vue.Plugin 类型的交叉类型，用于声明并挂载 install 方法
  ;(main as SFCWithInstall<T>).install = (app): void => {
    // 注册组件与扩展组件到 app 示例上 
    for (const comp of [main, ...Object.values(extra ?? {})]) {
      app.component(comp.name, comp)
    }
  }
  
  // 如果存在扩展组件，则将扩展组件挂载到主组件上
  if (extra) {
    for (const [key, comp] of Object.entries(extra)) {
      ;(main as any)[key] = comp
    }
  }
  // 返回被注册为插件的组件
  return main as SFCWithInstall<T> & E
}
```

withNoopInstall 方法则是一个将扩展组件（如 ElButtonGroup）注册为一个空 vue 插件的方法（因为在主组件时已经注册了扩展组件，所以不需要重复注册），防止在 install 时报错：

```ts
export declare const NOOP: () => void;
export const withNoopInstall = <T>(component: T) => {
  ;(component as SFCWithInstall<T>).install = NOOP

  return component as SFCWithInstall<T>
}
```

### classname

在观察组件源码的时候，我们会看到 ElementPlus 组件的几乎所有类名都是由 `useNamespace`  这个 hook 导出的方法生成的，这是因为组件的类名需要严格按照 [BEM](https://juejin.cn/post/6844903672162304013) 规范，简单来说，就是必须按照 `block__element-modifier` 这种命名规则，比如 `el-button--primary`、`el-table__cell`。除此之外，组件还会有 `is-disabled` 这种修饰状态的类。

useNamespace 这个 hook 就是用来按照规范生成各种类名的，其可以结构出如下几个方法：

- b(blockSuffix = '')：生成有 blockSuffix 的类名，如 el- button-group，什么都不传就可以生成只有 block 的类名如 el-button
- e(element?: string)：生成有 element 的类名，如 el-table__cell
- m(modifier?: string)：生成有 modifier 的类名，如 el-button--primary
- be(blockSuffix?: string, element?: string)：生成有 blockSuffix 和 element 的类名
- em(element?: string, modifier?: string)：生成有 element 和 modifier 的类名
- bm(blockSuffix?: string, modifier?: string)：生成有 blockSuffix 和 modifier 的类名
- bem(blockSuffix?: string, element?: string, modifier?: string)：生成有 blockSuffix、element 和 modifier 的类名
- is(name: string, ...args: \[boolean | undefined\] | \[\])：生成有 is- 的类名，如 is-disabled，是否生成该类由传入的参数决定
- cssVar(object: Record<string, string>)：生成 css 变量样式，如 {--el-key: value}
- cssVarBlock(object: Record<string, string>)：生成包含 blok 的 css 变量样式，如 {--el-button-key: value}
- cssVarName(name: string)：生成 css 变量名，如 --el-xxx
- cssVarBlockName(name: string)：生成包含 block 的 css 变量名，如 --el-button-xxx

`useNamespace` 的代码实现并不复杂，只是简单的拼接字符串。但其中的 namespace 概念需要单独说一下：默认情况下，namespace 就是 `el`，但是实际的代码实现中，namespace 是通过依赖注入获取的，这使得 ElementPlus 支持自定义组件库的 namespace，比如你可以通过 `app.provide(namespaceContextKey, 'xxx')` 来自定义组件库的 namespace，这样就可以生成 `xxx-button` 这样的类名了。

## 2.3 样式处理

# 3. 构建方案

# 4. 其他

