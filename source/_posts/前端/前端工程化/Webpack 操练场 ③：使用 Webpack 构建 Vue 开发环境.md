---
title: Webpack 操练场 ③：使用 Webpack 构建 Vue 开发环境
tags:
  - webpack
categories:
  - 前端
  - 前端工程化
date: 2023-12-26 17:39:33
---
# 使用 Webpack 构建 Vue 开发环境

对应代码：https://github.com/EsunR/webpack-playground/tree/main/templates/vue

> 本章节示例的 Vue 环境为 Vue3，基于 TypeScript 构建

## 调整 Eslint 规则

如果我们想要 Eslint 支持 Vue 的语法校验，可以通过安装如下几个包来实现：

```sh
pnpm install eslint-plugin-vue eslint-plugin-prettier-vue -D
```

- eslint-plugin-vue：使 eslint 支持 Vue 语法校验的插件
- eslint-plugin-prettier-vue：在 Vue 项目中使用该插件替代 eslint-plugin-prettier，以支持 Vue 语法校验

调整 eslint 配置为：

```js
module.exports = {
  extends: [
    '../../.eslintrc.cjs',
    // 使用 eslint 推荐规则集
    'eslint:recommended',
    // 使用 typescript eslint 配置和推荐规则集
    'plugin:@typescript-eslint/recommended',
    // 使用 vue3 配置和推推荐规则集
    'plugin:vue/vue3-recommended',
    // 替代 eslint-plugin-prettier，支持 vue 文件中的 prettier 的校验
    'plugin:prettier-vue/recommended',
  ],
  parserOptions: {
    /**
     * 在使用了 eslint-plugin-vue 后 parser 选项就会被修改为 vue 的 parser 导致无法解析 ts 文件
     * 为了不影响 ts 文件的解析，需要在此指定一个自定义的解析器来解析 ts 文件
     */
    parser: '@typescript-eslint/parser',
  },
  rules: {
    // 自定义规则集
    '@typescript-eslint/no-var-requires': 'off',
    '@typescript-eslint/no-explicit-any': 'off',
    'vue/multi-word-component-names': 'off',
  },
};
```

> 如果 extends 的配置太多，搞不清最终的配置长啥样，可以使用 pnpm exec eslint --print-config .eslintrc.cjs 可以查看最终的 eslint 配置。

## 准备 Vue 环境

安装 vue 相关的依赖：

```sh
pnpm install vue -S
pnpm install vue-loader vue-style-loader vue-template-compiler -D
```

- vue：Vue 核心库
- vue-loader：Vue 的 webpack loader
- vue-style-loader：Vue 的样式 loader，替代 style-loader，该 loader 是 style-loader 的代码库 fork，添加了对 scoped 样式与 SSR 相关的支持
- vue-template-compiler：Vue 模板编译器，会被 vue-loader 调用，需要独立安装

修改 `main.ts` 引入一个 Vue 组件：

```ts
import { createApp } from 'vue';
import '@/styles/global.css';
import App from './App.vue';

const app = createApp(App);

app.mount('#app');
```

修改 `public/index.html`，为 body 下插入 `#app` 节点：

```diff
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>vue template</title>
  </head>
  <body>
+   <div id="app"></div>
  </body>
</html>
```

## 使 Webpack 支持编译 Vue

修改 `webpack.config.ts`，添加对 Vue 的支持：

```ts
import { VueLoaderPlugin } from 'vue-loader';
import { DefinePlugin, Configuration as WebpackConfiguration } from 'webpack';
// ... ...

const config: WebpackConfiguration = {
  // ... ...
  module: {
    rules: [
      // 处理 Vue
      {
        test: /\.vue$/,
        exclude: /node_modules/,
        use: ['vue-loader'],
      },
      // 处理 ts
      {
        test: /\.tsx?$/,
        exclude: /node_modules/,
        use: [
          'babel-loader',
          {
            loader: 'ts-loader',
            options: {
              // 需要让 ts-loader 识别 vue SFC 中的 ts 代码
              appendTsSuffixTo: ['\\.vue$'],
            },
          },
        ],
      },
      // 加载样式
      {
        test: /\.css$/i,
        use: [
          // 使用 vue-style-loader 替换掉 style-loader
          isDev ? 'vue-style-loader' : MiniCssExtractPlugin.loader,
          'css-loader',
          'postcss-loader',
        ],
      },
      // ... ... 其他的 Loader
    ],
  },
  plugins: [
    // ... ...
    new VueLoaderPlugin(),
    /**
     * 使用 webpack 自带的 DefinePlugin 定义全局变量
     * __VUE_OPTIONS_API__、__VUE_PROD_DEVTOOLS__ 为 true 时候可以使用 Chrome 的 Vue Devtools 插件
     */
    new DefinePlugin({
      __VUE_OPTIONS_API__: isDev,
      __VUE_PROD_DEVTOOLS__: isDev,
    }),
  ],
};
```

关于 DefinePlugin 再多讲一点，这个插件是用于定义全局变量的，我们可以直接在代码中使用 `console.log(__VUE_OPTIONS_API__)` 来查看它的值（它并非挂载于 window 上，而是全局对象上）。但是如果你想要定义更多的全局变量，为了让 ts 和 eslint 不报错，你需要进行一系列的设置。

假如我们定义了全局变量：

```ts
new DefinePlugin({
  // ... ...
  IS_DEV: isDev,
});
```

我们需要在全局声明该变量的类型，可以在 `types` 目录下新建 `global.d.ts`：

```ts
declare const IS_DEV: boolean;
```

这样 ts 就不会报错了，但是如果我们使用了 eslint，它会报 `no-undef` 的错误，我们需要在 `.eslintrc.cjs` 中添加 `globals`：

```js
module.exports = {
  // ... ...
  globals: {
    IS_DEV: 'readonly',
  },
};
```

此外，为了不让 ts 引入 Vue 组件时报没有类型定义的错误，我们需要在 `types` 目录下新建 `vue-shim.d.ts`：

```ts
/* eslint-disable @typescript-eslint/ban-types */

declare module '*.vue' {
  import type { DefineComponent } from 'vue';

  const component: DefineComponent<{}, {}, any>;
  export default component;
}
```

此外，我们要调整以下 browserslist 的配置，之前的配置我们考虑到了 IE 浏览器，但是 Vue3 不支持 IE 浏览器，因此我们可以调整浏览器适配的范围，这样可以减少一些 polyfill 的代码。修改 `.browserlistrc` 文件：

```
> 0.2% and not dead
```

表示适配市场份额大于 0.2% 的浏览器，不包括已经停止维护的浏览器。
