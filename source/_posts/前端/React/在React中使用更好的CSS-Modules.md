---
title: babel-plugin-react-css-modules使用指南：在React中更好的使用CSS-Modules
tags:
  - React
  - webpack
categories:
  - 前端
  - React
date: 2020-04-29 10:55:31
---

# 1. babel-plugin-react-css-modules 简述

在 React 中对于 CSS 的解决方案通常有以下几种：

- Css 命名区间
- Css in Js
- Css Components
- Css Modules
  
个人比较喜欢使用 CSS Modules 的引入方式，但是其也有不方便的地方，由于其是基于判断 Class 来引入样式的，所以每次定义 Class 时总是需要调用 Css Modules 对象然后读取其某个 Class，如下：

```js
import style from "./style.modules.css"

// ... JSX ...
let Test = () => (
  <div className={style.test}>test text</div>
)
// ... JSX ...

export default Test
```

同时，使用 Css Module 如果引入了不存在 class 也不会报错。

那么为了解决这一问题，[react-css-modules](https://github.com/gajus/react-css-modules) 应运而生，其利用高阶组件的方式去自动将 className 中的样式连接到 CSS Modules 上，这样只需要只需要简单的书写 className 即可：

```js
import style from "./style.modules.css"
import CssModule from "react-css-modules"

// ... JSX ...
let Test = () => (
  <div className="test">test text</div>
)
// ... JSX ...

export default CssModule(style, Test)
```

但其仍有缺点，就是该插件是在运行时编译的，在虚拟 DOM 的生成中修改了 className，这样就会消耗客户端一定的性能，同时该插件已经停止维护，因此作者推荐使用 [babel-plugin-react-css-modules](https://github.com/gajus/babel-plugin-react-css-modules) 来进行替代。

与 react-css-modules 不同的是，babel-plugin-react-css-modules 借助 Babel 可以让 React 应用在构建时就直接替换掉 className 中的值，这样就会极高的提升性能。同时为了与 className 不冲突，babel-plugin-react-css-modules 规定了如果是引用 CSS Modules 中的 class 的话，可以使用 styleName 来进行样式的定义，如：

```js
import "./style.module.css";

let Test = () => (
  <div styleName="test">test text</div>
)

export default Test
```

# 2. 插件配置

## 2.1 前期准备

由于在 React 项目中，最常见的脚手架工具为 create-react-app，因此在此以该脚手架工具为示例，演示如何配置 babel-plugin-react-css-modules，并使其支持 less。

首先我们要安装插件：

```shell
npm install post-less -D # 对 less 语法进行处理，如果要处理 sass 这里就安装 post-sass
npm install babel-plugin-react-css-modules -S
```

这里要注意 babel-plugin-react-css-modules 需要作为运行时依赖安装，原因如下：

> 当babel-plugin-react-css-modules无法在编译时解析CSS模块时，它将导入一个辅助函数（读取运行时styleName解析）。因此，您必须安装babel-plugin-react-css-modules作为项目的直接依赖项。


由于这一部分需要修改 create-react-app 的 webpack 配置，因此我们还要通过逆向工程解构出 webpack 的配置：

```sh
yarn run eject
```

## 2.2 修改 babel 配置

babel-plugin-react-css-modules 基于 babel，其也是作为一个 babel 插件使用，所以按照官方文档，我们应该在 `.babelrc` 文件中配置该插件。由于 create-react-app 将 babel 配置文件集成到了 package.json 中，因此我们需要修改 package.json 的 babel 选项：

```json
// package.json
// ... ...
"babel": {
  "presets": [
    "react-app"
  ],
  "plugins": [
    ["react-css-modules",
    {
      "generateScopedName": "[local]-[hash:base64:10]",
      "filetypes": {
        ".less": {
          "syntax": "postcss-less"
        }
      }
    }]
  ]
}
// ... ...
```

这一步的目的是为了让 babel 在编译 js、jsx 文件时，将 JSX 语法中的 styleName 后缀一个 hash 值，并将其添加到 className 中，`generateScopedName` 选项控制了我们编译后的 className 的格式。同时为了支持 less，需要在 `filetypes` 选项中添加 postcss-less 以支持读取 less 文件(sass 则是添加 post-sass)。

此外，除了在 .babelrc 以及 package.json 文件中配置 babel 插件之外，我们还可以在 webpack 的 babel-lader 部分来配置这些信息，打开已经结构的 webpack 配置，找到 babel-loader 部分的配置，将其修改为：

```js
// Process application JS with Babel.
// The preset includes JSX, Flow, TypeScript, and some ESnext features.
{
  test: /\.(js|mjs|jsx|ts|tsx)$/,
  include: paths.appSrc,
  loader: require.resolve("babel-loader"),
  options: {
    customize: require.resolve(
      "babel-preset-react-app/webpack-overrides"
    ),

    plugins: [
      [
        require.resolve("babel-plugin-named-asset-import"),
        {
          loaderMap: {
            svg: {
              ReactComponent:
                "@svgr/webpack?-svgo,+titleProp,+ref![path]",
            },
          },
        },
      ],
      // ---- 新增 ----
      [
        "react-css-modules",
        {
          generateScopedName: "[local]-[hash:base64:10]",
          filetypes: {
            ".less": {
              syntax: "postcss-less",
            },
          },
        },
      ],
      // ---- 新增 ----
    ],
    // This is a feature of `babel-loader` for webpack (not Babel itself).
    // It enables caching results in ./node_modules/.cache/babel-loader/
    // directory for faster rebuilds.
    cacheDirectory: true,
    // See #6846 for context on why cacheCompression is disabled
    cacheCompression: false,
    compact: isEnvProduction,
  }
}
```

## 2.3 修改 css-loader 配置

我们目前已经可以使用标签的 styleName 属性了，我们可以在审查元素中看到，使用了 styleName 标签的 DOM 节点上，在 class 中出现了类似 `test-bs6rG6AQFi` 这样的 className，但此时样式还不会被应用，因为我们现在只处理了 jsx，还未处理 css 文件。

在 css-loader 中有一个 modules 配置选项，该配置项决定了是否开启 css modules，同时规定了 css modules 模式下的一些规范。因此在这一步，我们的目标就是让 css-loader 在处理 css 时启用 css modules 并且 css modules 的 class 命名格式要与 jsx 中的 styleName 处理后的命名格式相同，即都为 `[local]-[hash:base64:10]`。

create-react-app 中默认开启了 sass 的 css module，但是没有支持 less，因此我们先将 less 的 loader 添加上，并且开启 css module，同时配置 css-loader 的配置项，让其命名能够一致：

```js
// webpack.config.js
// 找到定义匹配 laoder 正则表达式的代码，并在后面追加 lessRegex 与 lessModuleRegex
const cssRegex = /\.css$/;
const cssModuleRegex = /\.module\.css$/;
const sassRegex = /\.(scss|sass)$/;
const sassModuleRegex = /\.module\.(scss|sass)$/;
const lessRegex = /\.less$/; // 新增
const lessModuleRegex = /\.module\.less$/; // 新增

// ... ...

// create-react-app 在 module.rules 中配置 相应文件的 loader
// 我们参考 sass-loader 的配置来配置 less-loader
{
  test: lessRegex, // 如果是 xxx.less 文件，而不是 xxx.module.less 文件，就不开启 css module，仅正常引入该 less 文件
  exclude: lessModuleRegex,
  use: getStyleLoaders(
    {
      importLoaders: 3,
      sourceMap: isEnvProduction && shouldUseSourceMap,
    },
    "less-loader"
  ),
  sideEffects: true,
},
{
  test: lessModuleRegex, // 如果是 xxx.module.less 文件，就开启 css module
  // getStyleLoaders 是 create-react-app 在 webpack 中定义的一个方法
  // 其目的是为了让所有 css 相关的 loader 最终都能被 css-loader 接管处理
  // 其提供了两个参数：
  // 1. options：定义 css-loader 的配置项
  // 2. pre：在 css-loader 之前进行的 loader
  use: getStyleLoaders(
    {
      importLoaders: 3,
      sourceMap: isEnvProduction && shouldUseSourceMap,
      modules: {
        /** 
        getCSSModuleLocalIdent 是 create-react-app 默认引入的一个方法，
        其作用是将处理后的 css module 重命名为规范的格式，
        原有的明明格式与我们需要的格式不一样（我们需要的格式为 [local]-[hash:base64:10]）,
        因此需要注释掉该配置项，否则我们接下来的配置不会生效
        **/
        // getLocalIdent: getCSSModuleLocalIdent,

        // localIdentName 规范了 css module 中 class 的命名格式，这里与我们 babel 中的配置要一致
        localIdentName: "[local]-[hash:base64:10]",
      },
    },
    "less-loader"
  ),
},
```

# 3. 使用测试

```less
.test {
  color: red;
}
```

```js
import React from "react";
import "./style.module.less";

class Layout extends React.Component {
  render() {
    return (
      <div id="layout">
        <div styleName="test">localIdentName</div>
      </div>
    );
  }
}

export default Layout;
```