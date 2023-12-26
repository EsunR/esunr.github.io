---
title: Webpack 操练场 ②：使用 Webpack 构建 TypeScript 开发环境
tags:
  - webpack
categories:
  - 前端
  - 前端工程化
date: 2023-12-26 17:38:52
---
# 使用 Webpack 构建 TypeScript 开发环境

对应代码：`/templates/html-ts`

## 准备 TypeScript 环境

首先安装 TypeScript：

```sh
pnpm install typescript -D
```

然后生成 tsconfig.json 配置文件：

```sh
pnpm exec tsc --init

# npm
npx tsc --init
```

这时候根目录就会生成 `tsconfig.json` 文件，这个文件是 TypeScript 的配置文件，我们可以在这个文件中配置 TypeScript 的编译选项，我们调整如下几个选项：

```json
{
  "compilerOptions": {
    "target": "ES5", // 将代码转为 ES5 语法
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

之后我们将 `webpack.config.js` 修改为 `webpack.config.ts`，并将代码规范修改为 ESM，这样就可以编写有 TypeScript 提示的 webpack 配置了：

```ts
import path from 'path';
// 引入 webpack 的类型
import type { Configuration as WebpackConfiguration } from 'webpack';
// 保证配置 devServer 时不会报类型错误
import 'webpack-dev-server';

const isDev = process.env.NODE_ENV !== 'production';

// 通过 TypeScript 我们可以添加类型声明
const config: WebpackConfiguration = {
  mode: isDev ? 'development' : 'production',
  devtool: isDev ? 'eval-cheap-module-source-map' : 'source-map',
  entry: path.resolve(__dirname, './src/main.ts'),
  output: {
    path: path.resolve(__dirname, './dist'),
    clean: true,
  },
  // 其他 webpack 配置
};

export default config;
```

然后修改启动脚本：

```diff
{
  "scripts": {
-   "dev": "cross-env NODE_ENV=development webpack serve --config webpack.config.js",
+   "dev": "cross-env NODE_ENV=development webpack serve --config webpack.config.ts",
-   "build": "cross-env NODE_ENV=production webpack --config webpack.config.js"
+   "build": "cross-env NODE_ENV=production webpack --config webpack.config.ts"
  }
}
```

执行构建指令后会报错，这是因为我们只安装了 typescript 环境，但是如果想让 webpack 执行 TypeScript 的配置文件还需要 TypeScript 的运行执行指令，因此我们需要安装 [ts-node](https://www.npmjs.com/package/ts-node)，ts-node 可以让我们在直接运行 ts 代码而不需要编译成 js：

```sh
pnpm install ts-node -D
```

之后，webpack 就可以成功执行 TypeScript 编写的 webpack 配置文件了。

## 添加 ts-loader

准备完环境后，我们将 js 代码修改为 ts 代码后，webpack 会报错，这是因为 webpack 默认只能处理 js 代码，如果要处理 ts 代码，需要添加对应的 loader，这里我们使用 [ts-loader](https://www.npmjs.com/package/ts-loader) 来处理 ts 代码：

```sh
pnpm install ts-loader -D
```

向 `webpack.config.ts` 中添加对应的 loader，同时要让 webpack 支持 ts 模块的解析:

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
  resolve: {
    alias: {
      // ... ...
    },
    // 将 .ts (如果有需要也要加入 .tsx) 文件添加到解析列表中，否则在 import ts 模块时，如果不带文件后缀就会报错
    extensions: ['.js', '.ts', '.tsx'],
  },
};
```

> 除了 ts—loader，因为项目中使用了 babel，还可以使用 [babel-loader](https://www.npmjs.com/package/babel-loader) 结合 [@babel/preset-typescript](https://www.npmjs.com/package/@babel/preset-typescript) 来处理 ts，但是这样不支持类型检查，这里不再做演示。
>
> 另外，如果追求编译速度，可以使用 esbuild 或者使用 swc 替换 babel。

## 处理静态资源模块

当引用静态资源时，ts 会报类型错误。

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202312061838999.png)

这是因为 ts 无法识别我们导入的静态资源模块，通过编写类型声明文件可以解决这个问题。在 `src` 目录下创建 `types` 文件夹，并新建 `static.d.ts` 文件：

```ts
declare module '*.css' {
  const classes: { readonly [key: string]: string };
  export default classes;
}

declare module '*.png' {
  const url: string;
  export default url;
}

declare module '*.jpg' {
  const url: string;
  export default url;
}

declare module '*.jpeg' {
  const url: string;
  export default url;
}

declare module '*.gif' {
  const url: string;
  export default url;
}

declare module '*.svg' {
  const url: string;
  export default url;
}

declare module '*.webp' {
  const url: string;
  export default url;
}
```

这样，引入静态资源模块时，ts 就不会报类型错误的问题了。

## ts-loader 结合 babel-loader

参考：[《在 Webpack 中同时使用 ts-loader 和 babel-loader》](https://blog.esunr.xyz/2023/12/88456067f15c.html)
