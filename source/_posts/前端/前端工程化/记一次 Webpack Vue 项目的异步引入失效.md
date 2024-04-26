---
title: 记一次 Webpack Vue 项目的异步引入失效
tags:
  - webpack
  - Vue
  - 异步引入
  - esm
  - cjs
categories:
  - 前端
  - 前端工程化
date: 2024-04-26 11:21:15
---
# 1. 问题发现

在回顾 [webpack-playground](https://github.com/EsunR/webpack-playground) 这个项目的 Vue + TS 模板时，意外发项目中使用 `import` 异步引入模块时是失效的，代码正常被执行，但是并没有异步引入该方法，方法如下：

```js
const addCount = (num: number) => {
  import(/* webpackChunkName: "lodash" */ 'lodash').then(({ default: _ }) => {
    count.value = _.add(count.value, num);
  });
};
```

但是打包后，并没有将异步引入的 lodash 单独打成一个模块，构建出的代码也只有一个 `main.js` 文件：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240425215244.png)

同样的，异步引入的路由也不会被正常拆分成单独的模块，Element Plus 引入的组件也不会进行 tree shake。

# 2. 问题解决

查看编译后的 `main.js` 发现了 lodash 整个文件都被打入了，找到异步 import 调用的位置，发现代码被编译为：

```js
const addCount = num => {
  Promise.resolve().then(() => __importStar(__webpack_require__( /* webpackChunkName: "lodash" */378))).then(_ref => {
	let {
	  default: _
	} = _ref;
	count.value = _.add(count.value, num);
	console.log('find it!!!!');
  });
};
```

而模块 `378` 正是被 webpack 打入的 lodash，位于 `main.js` 中：

```js
/***/ 378:
/***/ (function(module, exports, __webpack_require__) {

/* module decorator */ module = __webpack_require__.nmd(module);
var __WEBPACK_AMD_DEFINE_RESULT__;/**
 * @license
 * Lodash <https://lodash.com/>
 * Copyright OpenJS Foundation and other contributors <https://openjsf.org/>
 * Released under MIT license <https://lodash.com/license>
 * Based on Underscore.js 1.8.3 <http://underscorejs.org/LICENSE>
 * Copyright Jeremy Ashkenas, DocumentCloud and Investigative Reporters & Editors
 */
;(function() {

  /** Used as a safe reference for `undefined` in pre-ES5 environments. */
  var undefined;

  /** Used as the semantic version number. */
  var VERSION = '4.17.21';

  /** Used as the size to enable large array optimizations. */
  var LARGE_ARRAY_SIZE = 200;
  // ... ...
```

如果是使用了 import 的异步引入，webpack 是不会将其处理为 `Promise.resolve` 的，**而是将其处理为 webpack 自己的异步引入方法**，如下是一个生效的正常的异步引入代码被 webpack 打包后的结果（关闭混淆）：

```js
// i 是
const addCount = num => {
  __webpack_require__.e(/* import() | lodash */ 202).then(__webpack_require__.t.bind(__webpack_require__, 9378, 23)).then(_ref => {
	let {
	  default: _
	} = _ref;
	count.value = _.add(count.value, num);
	console.log('find it!!!!');
  });
};
```

这就很奇怪了，为什么 webpack 没有将异步 import 的代码成功转换呢？

思考后想到由于这是一个 Typescript 项目，我们编写的 ts 代码是会先被 `ts-loader` 处理成 js，然后再交给 webpack 处理的，那会不会是这里出现了问题，而 `ts-loader` 使用的是 Typescript 官方编译器 tsc，因此我们在该项目的工作目录下使用 tsc 编译 ts 文件，就能调出来 `ts-loader` 处理后、webpack 处理前的 js 代码。

说干就干，这里我们简化一下，只将异步引入 lodash 的代码拿出来写到一个 ts 文件里进行编译。

编译前的 ts 代码：

```ts
import("lodash").then((_) => {
  console.log(_.camelCase("Hello world"));
});
```

在当前项目中编译后的 ts 代码：

```js
Promise.resolve().then(function () { return require("lodash"); }).then(function (_) {
    console.log(_.camelCase("Hello world"));
});
```

到这里基本上破案了，我写的异步 import 被 tsc 按照 commonjs 规范编译成了 require，webpack 自然就会将 lodash 按照按照同步代码的方式去打包了。

对比一下上面经过  webpack 处理后的代码，可以感受一下 webpack 拿到上面的代码的处理过程：

```js
Promise.resolve().then(() => __importStar(__webpack_require__( /* webpackChunkName: "lodash" */378))).then(_ref => {
	let {
	  default: _
	} = _ref;
	count.value = _.add(count.value, num);
});
```

要想让 tsc 不讲代码转成 commonjs，我们需要修改 `tsconfig.json` 的配置，具体要动的配置项如下：

```diff
- "module": "commonjs",
+ "module": "ESNext",
+ "moduleResolution": "node10",
+ "esModuleInterop": true,
```

此外还要注意一点，如果你的 webpack 构建文件是用 ts 编写的，修改后执行 webpack 构建可能会报错，这是因为上面我们修改了 `tsconfig.json` 配置，所以会导致 `ts-node`（webpack 使用了 `ts-node` 来运行 webpack 的 Typescript 构建文件）使用 ESModule 去编译代码。但因为我们大多数编写的 webpack 配置文件都是按照 commonjs 规范写的（比如使用了 `__dirname`、`require` 语法），同时 webpack 一些相关的包都是 cjs 包，因此在 ESM 规范下必然会报错。

为了解决这一问题也很简单，`tsconfig.json` 中添加 `ts-node` 字段可以单独指定 `ts-node` 的运行配置，我们让 `ts-node` 还在 cjs 规范下运行即可：

```json
"ts-node": {
	"compilerOptions": {
	  "target": "ESNext",
	  "module": "CommonJS",
	  "esModuleInterop": true
	}
}
```

ALL DONE 🎉

[完整的代码修复参考](https://github.com/EsunR/webpack-playground/commit/0c36c93d0ed56cf8f9ca8fd1ef13e14b026170f5)
