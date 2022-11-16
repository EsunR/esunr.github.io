---
title: 开发环境下如何使用 tsconfig 配置的 paths（路径别名）
tags:
  - NodeJS
  - Typescript
  - 路径别名
  - nodemon
categories:
  - 前端
  - 前端工程化
date: 2022-11-16 16:31:57
---

在开发基于 Typescript 的 NodeJS 项目时，我们通常会 `tsconfig.json` 中配置 `paths` 字段来设置路径别名（[文档](https://www.typescriptlang.org/tsconfig#paths)）：

```json
{
  "compilerOptions": {
	"paths": {
		"@/*": ["./src/*"]
	}
  }
}
```

但这里很容让人产生一个错误认知，很多人会意为这里配置的路径别名与 webpack 中配置的 `alias` 是一样的，我们配置完 `paths` 后就去写下如下代码：

```ts
import {xxx} from "@/xxx"
```

然后使用 tsc 进行编译或者使用 ts-node 运行代码，就必定发生如下报错：

```
Error: Cannot find module '@/xxx'
```

这里我们需要认识到如下两点：

1. 在 `tsconfig.json` 中配置的路径别名，只触发 vscode 的包索引，得以让你使用代码提示来找文件路径；
2. tsc、ts-node 在编译 ts 文件时，不会通过 `tsconfig.json` 中配置的 `paths` 来进行包索引，你可以查看编译后的 js 文件，文件路径仍保持编码时的形态，并没有得到转换，因此在 nodejs 运行时必定会发生无法查找到模块路径的报错。

为了解决上述的问题，可以使用如下解决方案：

# 1. module-alias

[module-alias](https://www.npmjs.com/package/module-alias) 是一个在运行时对模块路径进行转换的插件，你可以通过将路径别名写入到 `package.json` 或者是入口文件的顶部，即可让你的代码在运行时使用路径别名。

示例：

```ts
// 入口文件

// 必须保证路径别名的声明代码，在所有代码引入操作前执行
import "module-alias/register"
import moduleAlias from "module-alias"
import path from "path"
moduleAlias.addAliases({
  "@": path.resolve(__dirname, "./"),
})

// 使用路径别名导入模块
import { cloneDeep } from "@/utils"
```

使用 `module-alias` 的好处是让代码在运行时进行路径解析，意为着你不需要考虑开发时和编译后的代码路径转换问题，但是这样会导致你不仅需要在 `tsconfig.json` 中写入路径别名，也需要在 `module-alias` 使用时声明路径别名。

同时运行时解析路径意味着路径解析是动态的，效率上必定会有所损失。

# 2. tsconfig-paths

[tsconfig-paths](https://www.npmjs.com/package/tsconfig-paths) 是比 `module-alias` 更好的一个替代模块，它的原理跟 `modules-alias` 是相似的，但是它会自动读取 `tsconfig.json/jsconfig.json` 中配置的路径别名，意味着你不需要二次配置，它有两种使用方式，一种是在代码入口中直接引入该包的 register：

```ts
// 保证 register 先被加载
import "tsconfig-paths/register"
// 使用路径别名导入模块
import { cloneDeep } from "@/utils"
```

另外一种则是通过官方推荐的在 `node/ts-node` 运行指令中使用 [`-r` 参数](https://www.nodeapp.cn/cli.html#cli_r_require_module) 来引入 register：

```sh
# node
node -r tsconfig-paths/register ./src/main.js
# ts-node
ts-node -r tsconfig-paths/register ./src/main.ts
```

如果你使用了 `nodemon` 作为开发时监听代码变更的工具，虽然 nodemon 会自动根据当前环境选择调用 node 还是 ts-node 作为代码的运行时环境，但并不会去调用 `tsconfig-paths/register`，因此我们可以编写一个 `nodemon.json` 文件来改写 node 执行代码时的行为：

```json
{
  "watch": [
    "./src"
  ],
  "exec": "ts-node -r tsconfig-paths/register ./src/main.js",
  "ext": "ts, js"
}
```

# 3. 使用前端编译工具解析模块别名

上述的两种方案都是让代码在运行时解析文件路径，因此在运行时必定会有一定的性能损耗，这个性能损耗在开发环境下我们可以无视掉，但是在正式环境下我们还是希望可以直接生成一个可以访问的静态路径，避免路径转换带来一定的损耗。

要达到这个目的我们不得不借助前端编译工具来实现路径转换，以 rollup 为例：

```ts
import alias from "@rollup/plugin-alias"

const rollupOption: RollupOptions = {
	input,
	plugins: [
	  // 使用 @rollup/plugin-alias 来解析路径别名
	  alias({
		entries: [
		  {
			find: "@",
			replacement: path.join(__dirname, "./src"),
		  },
		],
	  }),
	  // ... ...
	]
}
```

这样编译后的代码就实实在在的转化为了一个可以被查找到的 **相对路径**，比如：

```ts
// 编译前
import { cloneDeep } from "@/utils"
// 编译后（编译后路径添加 `/index.js` 的行为是由 @rollup/plugin-node-resolve 插件实现的，@rollup/plugin-alias 只负责将路径别名转换为正确的相对路径）
import { cloneDeep } from "../../utils/index.js"
```

# 4. 总结

- `tsconfig.json` 声明的路径别名并**不会**被 tsc 识别并进行转换，仅供 vscode 的路径提示可以识别；
- 在开发环境下可以使用 `tsconfig-paths` 来做路径转换；
- 在最终的编译阶段，最好还是使用编译工具来进行路径转换。