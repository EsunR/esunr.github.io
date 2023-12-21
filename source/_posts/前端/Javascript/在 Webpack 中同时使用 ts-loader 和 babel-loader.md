---
categories:
  - 前端
  - Javascript
---
# 1. 为什么要同时使用 ts-loader 和 babel-loader

在使用 Webpack 构建 TypeScript 项目时，我们通常会使用 `ts-loader` 来加载 ts 代码，`ts-loader` 会根据目标 `tsconfig.json` 文件调用 TypeScript Compiler 来对 ts 文件进行编译。

我们可以在 `tsconfig.json` 中可以通过 `target` 选项来指定输出的 ES 版本，但是 TypeScript 编译后的代码只支持对语法的转义，比如将 ES6 的箭头函数转为 ES5 支持的函数写法，而那些高版本 ES 中的新特性，比如 Promise、Map、Set，经过 TypeScript 编译器编译后的代码如果只在 ES5 环境的浏览器中运行，那么这些对象还是 undefined。这是因为 TypeScript 编译器只支持语法降级，但并不会添加语法垫片（polyfill）。

> 有些同学可能会被 `tsconfig.json` 中的 `lib` 配置项给误导到，实际上 lib 只是引入了某些语法的类型声明，并不会添加语法垫片。

但是 babel 是支持为高版本的 ES 代码添加语法垫片的，因此如果我们需要让 ts 代码完全支持低版本的浏览器，就需要在 webpack 配置中添加 babel-loader 到 ts-loader 的流程中，让 ts-loader 编译后的代码再过一遍 babel-loader。

> 注意：本文只在阐述使用 ts-loader 时，同时使用 babel-loader 的情况，但并不意味着你必须使用 ts-loader 来处理 TypeScript 代码，babel 也可以编译 TypeScript 代码，如果你的开发流程中明确不会使用 ts-loader 你完全可以将 ts 代码也交给 babel-loader 处理，那么也不需要看本文了。

我们可以将 webpack 的配置修改为：

```ts
const config: WebpackConfiguration = {
  // ... 其他配置
  module: {
    rules: [
      // ... 其他 loader ...
      // 处理 ts 文件
      {
        test: /\.tsx?$/i,
        use: [
          'babel-loader',
          {
            loader: 'ts-loader',
            options: {
              // 指定特 tsconfig 的位置，也可以不指定，默认使用项目根目录的 tsconfig.json
              configFile: path.resolve(__dirname, './tsconfig.json'),
            },
          },
        ],
        exclude: /node_modules/,
      },
    ],
  },
  // ... ...
};
```

tsconfig.json：

```json
{
  "compilerOptions": {
    "target": "ESNext", // 因为语法转换交给 Babel 处理，因此目标语法为 ESNext，即不让 tsc 处理最新的语法
    "module": "CommonJS", // 使用 CommonJS 规范
    "moduleResolution": "node10", // 模块解析方式，不配置在引用模块时如果不是完整路径会报错
    "baseUrl": "./",
    "paths": {
      "@/*": ["src/*"]
    }, // 配置路径别名，主要让 vscode 识别，跟 webpack.config.js 中的 alias 保持对应
    "allowJs": true, // 允许编译 js 文件
    "outDir": "./dist" // 编译产出，我们使用 webpack 不会根据这里的配置走，但是如果不配置 tsconfig 会报错
    // 其余配置保持默认不改动
  }
}
```

babel.config.cjs

```js
module.exports = {
  presets: [
    [
      '@babel/preset-env',
      {
        corejs: 3, // 为代码添加语法垫片
        useBuiltIns: 'usage',
      },
    ],
  ],
  plugins: [
	  '@babel/plugin-transform-runtime', // 优化编译产出
  ],
};
```

# 2. 发现问题

思路是没问题的，但是如果我们按照上面的配置去编译现有的代码，可能会遇到编译失败的情况，如：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202312201124489.png)

也可能遇到编译成功了但是浏览器无法运行的情况，如：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202312201125078.png)

这些问题都是因为 TypeScript 编译器与 Babel 在包模块规范上产生了冲突。

通常情况下，如果我们的项目使用了 TypeScript， `tsconfig.json` 中配置的 `module` 为 `CommonJS`，就意味着 TypeScript 会将我们的 ESM 规范的代码转义为 CommonJS 规范；然而当代码交给 Babel 处理时，`@babel/preset-env` 会对 TypeScript 转化后的 CommonJS 代码判断有问题（不知道是不是 bug），导致代码没有从 CommonJS 转换为浏览器可以识别的模块语法；同时，由于 TypeScript 将 ESM 转为了 CommonJS，用于区分 ESM 规范的 `__esModule` 也被占用了，就会导致某些 babel 的 plugin 也出现无法编译的报错。

# 3. 问题解决

## 修正 `@babel/preset-env` 的模块规范判断

我们只需要添加 `modules: "cjs"` 到 `@babel/preset-env` 的配置项中，让 Babel 将 ESM 转为 CommonJS（原来由 [@babel/plugin-transform-modules-commonjs](https://babeljs.io/docs/babel-plugin-transform-modules-commonjs) 实现），即可让 Babel 成功编译由 TypeScript 编译出的 CommonJS 规范的代码：

```diff
module.exports = {
  presets: [
    [
      '@babel/preset-env',
      {
        corejs: 3, // 为代码添加语法垫片
        useBuiltIns: 'usage',
+       modules: "cjs",
      },
    ],
  ],
  plugins: [
	  '@babel/plugin-transform-runtime', // 优化编译产出
  ],
};
```

## 让 TypeScript 编译出 ESM 规范的代码

最简单的一种理解是让 TypeScript 编译出 ESM 模块规范的代码，这样代码的转化就还是跟 babel-loader 处理普通的 js 代码一样，代码由 ESM 转为浏览器可以运行的代码。

首先我们需要将 `tsconfig.json` 做出一些变更，让 TypeScript 可以编译出 ESM 规范的代码：

```diff
{
	//... ...
-   "module": "CommonJS",
+   "module": "ESNext",
-   "module": "CommonJS",
+   "module": "ESNext",
+   "esModuleInterop": true
}
```

然后，修改 `package.json` 的 `type` 为 `module`，标记当前项目为 ESM 规范：

```diff
{
  "name": "@webpack-playground/html-ts",
+ "type": "module",
  // ... ...
}
```

如果项目内有 `.cjs` 模块，则需要转为 `.mjs`，如：

- babel.config.cjs => babel.config.mjs
- postcss.config.cjs => postcss.config.mjs

此时执行 webpack 指令时会报错，因为 webpack 调用的 ts-node 并没有使用 esm 的加载器，会被 node 监测出在 `type: "module"` 的项目中使用了 CommonJS 规范。那么需要指定 webpack 的模块加载器为 `ts-node/esm`，修改 package.json 中的 script：

```diff
{
  "name": "@webpack-playground/html-ts",
  "type": "module",
  "scripts": {
-   "dev": "cross-env NODE_ENV=development webpack serve --config webpack.config.ts",
+   "dev": "cross-env NODE_ENV=development node --loader ts-node/esm node_modules/webpack-cli/bin/cli.js serve --config webpack.config.ts",
-   "build": "cross-env NODE_ENV=production webpack --config webpack.config.ts",
+   "build": "cross-env NODE_ENV=production node --loader ts-node/esm node_modules/webpack-cli/bin/cli.js --config webpack.config.ts"
  },
  // ... ...
}
```

此外如果使用了 CommonJS 中的语法，比如 `__dirname` 需要添加语法垫片：

```ts
import url from 'url';
const __dirname = url.fileURLToPath(new URL('.', import.meta.url));
```

这样，项目内的 ts 代码经过 tsc 编译后就会编译为 ESM 规范的代码，ESM 规范的代码再交由 Babel 和 Webpack 处理就没有问题了。

如果项目不方便修改 `package.json` 中的 `module`，那么还可以单独为 ts-loader 编写一个 `tsconfig.json` 配置进行加载，比如创建一个 `tsconfig-project.json`：

```json
{
  "compilerOptions": {
    "target": "ESNext", // 因为语法转换交给 Babel 处理，因此目标语法为 ESNext，即不让 tsc 处理最新的语法
    "module": "ESNext", // 使用 ESM 规范
    "moduleResolution": "node10", // 模块解析方式，不配置在引用模块时如果不是完整路径会报错
    "baseUrl": "./",
    "paths": {
      "@/*": ["src/*"]
    }, // 配置路径别名，主要让 vscode 识别，跟 webpack.config.js 中的 alias 保持对应
    "allowJs": true, // 允许编译 js 文件
    "outDir": "./dist", // 编译产出，我们使用 webpack 不会根据这里的配置走，但是如果不配置 tsconfig 会报错
    "esModuleInterop": true
    // 其余配置保持默认不改动
  }
}
```

然后将 ts-loader 的配置修改为：

```diff
const config: WebpackConfiguration = {
  // ... 其他配置
  module: {
    rules: [
      // ... 其他 loader ...
      // 处理 ts 文件
      {
        test: /\.tsx?$/i,
        use: [
          'babel-loader',
          {
            loader: 'ts-loader',
            options: {
-             configFile: path.resolve(__dirname, './tsconfig.json'),
+             configFile: path.resolve(__dirname, './tsconfig-project.json'),
            },
          },
        ],
        exclude: /node_modules/,
      },
    ],
  },
  // ... ...
};
```