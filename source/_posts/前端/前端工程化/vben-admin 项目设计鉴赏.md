---
title: veben-admin 项目设计鉴赏
tags:
  - Vue
  - 前端工程化
categories:
  - 前端
  - 前端工程化
date: 2025-01-09 20:23:45
---
# 使用 catalog 统一 monorepo 项目的包依赖版本号

[官方文档](https://pnpm.io/catalogs)

在 monorepo 项目中，各个子模块中依赖的“基础” npm pacakge 他们的版本号应该是一致的，比如：

- 在 Vue 项目中，各个模块的 Vue 版本应该保持一致；
- eslint、prettier、typescript 这种开发依赖都应该保持一致，方便维护；

但你也可以用一些方案来规避这一问题：

- 将这些“公共包”都使用 `pnpm install xxx -w` 安装在工作区目录，从而保证全局的模块都是从根目录寻包，但是对于 monorepo 的设计思想来说，每个子包的依赖都应该是独立的，所以这一做法实际上并不稳妥，它会逐渐导致你子包的依赖变得不清晰，也会让子包的依赖散落的导出都是；
- 使用 `pnpm dedupe` 来将已安装的包统一到当前可用的最高版本；

pnpm catalog 就是用来处理这一问题的，我们可以在 `pnpm-workspace.yaml` 中声明 catalog 配置来定义项目中公共包的版本号，比如：

```yaml
catalog:
	vue: ^3.5.13
	'@vue/reactivity': ^3.5.13
	'@vue/shared': ^3.5.13
	'@vue/test-utils': ^2.4.6
	'@vueuse/core': ^12.2.0
```

此时，如果你在子包使用 `pnpm add vue`，那么在子包的 `package.json` 中，这些在 catlog 中定义过的包就会变为：

```json
"dependencies": {
	"vue": "catalog:",
	... ...
}
```

# 使用 unbuild 构建子包

unbuild 是一个基于 rollup 的、开箱即用的构建工具，其内部集成了多中 rollup 插件并自动启用，因此用于快速构建一个基于 Typescript 的 JavaScript lib 是一个非常好的选择。vben 将其用于 lib 的构建工具之外，最主要的是利用了其可以编译 JIT（运行时编译）包来简化重新构建依赖的负担。

unbuild 引入了 jiti 用于将 ts 源码文件进行实时编译，当我们执行 `unbuild --stub` 后，unbuild 并不会直接生成一个 js bundle，而是生成一个入口文件，如下：

```js
import { createJiti } from "../../../../node_modules/.pnpm/jiti@2.4.2/node_modules/jiti/lib/jiti.mjs";

const jiti = createJiti(import.meta.url, {
  "interopDefault": true,
  "alias": {
    "@vben/eslint-config": "/Users/jiguangrui/Documents/code/demo/vue-vben-admin/internal/lint-configs/eslint-config"
  },
  "transformOptions": {
    "babel": {
      "plugins": []
    }
  }
})

/** @type {import("/Users/jiguangrui/Documents/code/demo/vue-vben-admin/internal/lint-configs/eslint-config/src/index.js")} */
const _module = await jiti.import("/Users/jiguangrui/Documents/code/demo/vue-vben-admin/internal/lint-configs/eslint-config/src/index.ts");

export const defineConfig = _module.defineConfig;
```

入口文件利用 `jiti.import` 将源码文件进行了引用，这样当其他的代码引用了 unbuild 构建的代码后其实是调用 jiti 的运行时函数，实时的将源码编译为 js。

vben 将 `internal` 目录下使用 TS 编写的包都使用 unbuild 生成了 JIT 包，这样既保证了 node 能够正常运行这些经过 jiti 包装过的 TS 代码，又不需要实时的对代码进行重新编译，减轻了开发负担。

# BEM 类名规范实践