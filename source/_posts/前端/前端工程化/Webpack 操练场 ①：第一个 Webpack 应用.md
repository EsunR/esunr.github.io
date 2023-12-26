---
title: Webpack 操练场 ①：第一个 Webpack 应用
tags:
  - webpack
categories:
  - 前端
  - 前端工程化
date: 2023-12-26 17:37:23
---
# 第一个 Webpack 应用

对应代码：https://github.com/EsunR/webpack-playground/tree/main/templates/html

## 安装 webpack

```sh
# npm
npm install webpack webpack-cli -D

# pnpm（本项目）
pnpm install webpack webpack-cli -D
```

- webpack：webpack 的核心库，提供了 webpack 的核心打包功能
- webpack-cli：webpack 的命令行工具，提供了 webpack 的命令行功能，使得用户可以在命令行中运行 webpack

## 定义出入口

webpack 只需要配置一个入口和一个出口，就已经可以进行基础的打包了，通过以下两个配置可以定义：

- entry 代码入口
- output 配置编译产出

创建 `webpack.config.cjs` 文件：

```js
const path = require('path');

module.exports = {
  mode: 'production',
  // 入口
  entry: path.resolve(__dirname, './src/main.js'),
  output: {
    // 输出路径
    path: path.resolve(__dirname, './dist'),
    // 每次打包前清空 dist 目录
    clean: true,
  },
};
```

output.path 必须是绝对路径，因此会用到下面的方法来获取绝对路径：

- `path.resolve()` 方法会把一个路径或路径片段的序列解析为一个绝对路径
- `__dirname` 是 node.js 中的一个全局变量（仅 CommonJS 环境），它指向当前执行脚本所在的目录

因此，`path.resolve(__dirname, "./dist")` 代表的就是当前目录下的 dist 目录。

> 什么是相对路径：相对路径是相对于当前工作目录或者当前文件的路径来表示目标文件的位置。它以当前位置为基准，通过使用特定的路径规则来定位文件。相对路径往往使用相对于当前目录的文件路径，或者相对于当前文件所在目录的路径。例如，在当前目录下的文件A中使用相对路径”../fileB”来引用上级目录下的文件B，即表示A所在目录的上级目录。

> 什么是绝对路径：绝对路径是从文件系统的根目录开始的完整路径名称，它可以准确地定位文件或目录的位置。绝对路径描述的是文件或目录的完整路径，不论当前工作目录是什么，它总是可以指向相同的位置。例如，在UNIX系统上，绝对路径可能是”/usr/local/bin/fileA”，在Windows系统上可能是”C:\Program Files\fileA”。

在终端输入 webpack 指令进行构建：

```sh
# npm
npx webpack --config webpack.config.cjs

# pnpm（本项目）
pnpm exec webpack --config webpack.config.cjs
```

为了方便使用，我们将执行 webpack 构建的命令行指令写入到 package.json 的 script 中：

```json
{
  "scripts": {
    "build": "webpack --config webpack.config.cjs"
  }
}
```

这样就可以通过 `npm run build` (npm 管理) 或 `pnpm build` (pnpm 管理) 来执行 webpack 构建了。

## 处理 HTML

使用 [html-webpack-plugin](https://github.com/jantimon/html-webpack-plugin) 插件：可以将 JS 引入到 HTML 中

```js
const HtmlWebpackPlugin = require('html-webpack-plugin');

module.exports = {
  // webpack 其他配置
  plugins: [
    new HtmlWebpackPlugin({
      // 在这里可以填写插件配置，如模板位置、注入 css、js 的方式等
      // 文档：https://github.com/jantimon/html-webpack-plugin#options
      template: path.resolve(__dirname, './public/index.html'),
    }),
  ],
};
```

## 处理 CSS

loader: webpack 会将所有的资源都作为模块引入，但是引入相对应的资源必须有对应的 loader 才可以。

处理 css 必须使用以下两个 loader：

- css-loader：只负责编译 css 代码，让 import、require、@import、url 语法生效，成功引入 css 模块，但不负责让 css 生效
- style-loader：将 css-loader 的产出，注入到 html 里

添加样式处理的 Loader:

```js
module.exports = {
  // webpack 其他配置
  module: {
    rules: [
      // ... 其他 loader ...
      // 处理 css 文件
      {
        test: /\.css$/i,
        use: [
          // loader 的执行顺序是从后往前的，因此先执行 css-loader，再执行 style-loader
          'style-loader',
          'css-loader',
        ],
      },
    ],
  },
};
```

`style-loader` 会使用 js 将 css 代码注入到 html 里，如果想要将 css 代码单独抽离出来，可以使用 `mini-css-extract-plugin` 插件

```js
const MiniCssExtractPlugin = require('mini-css-extract-plugin');

module.exports = {
  // webpack 其他配置
  module: {
    rules: [
      // ... 其他 loader ...
      // 处理 css 文件
      {
        test: /\.css$/i,
        use: [
          // 'style-loader',
          MiniCssExtractPlugin.loader,
          'css-loader',
        ],
      },
    ],
  },
  plugins: [
    // 注意：mini-css-extract-plugin 还包含一个插件需要引入
    new MiniCssExtractPlugin(),
  ],
};
```

## 处理静态资源

webpack4 需要使用 file-loader 处理静态资源

但是 webpack5 内置了静态资源 loader，通过指定模块类型为 `asset/resource` 就可以让 webpack 自动使用静态资源 loader：

```js
module: {
  rules: [
    // ... 其他 loader ...
    // 处理静态资源
    {
      test: /\.(png|svg|jpg|jpeg|gif|mp3|mp4)$/i,
      type: 'asset/resource',
    }
  ],
},
```

## 路径别名

通过 `resolve.alias` 配置路径别名，让 webpack 识别：

```js
module.exports = {
  // webpack 其他配置
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
};
```

但同时，还需要让 vscode 认识配置的路径别名，通过创建一个 `jsconfig.json` 文件来声明路径别名：

```json
{
  "compilerOptions": {
    "baseUrl": "./",
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

## devServer

https://webpack.docschina.org/configuration/dev-server/

安装完 `webpack-dev-server` 后，添加 dev 指令到 package.json

```json
{
  "scripts": {
    "dev": "webpack serve --config webpack.config.cjs",
    "build": "webpack --config webpack.config.cjs"
  }
}
```

在终端运行 `pnpm dev` 就可以启动 dev server 了。

## Source map 源代码映射

如果我们的代码中存在一行报错，那么在没有配置 source map 的情况下，浏览器控制台显示的是编译后的代码，这样我们很难定位到错误的位置。

如下，我们根据控制台报错信息，定位到的代码是经过编译的，并且不会告诉我们具体文件的第几行出错了：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202312061421050.png)

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202312061421633.png)

因此 webpack 提供了一种生成源代码映射文件的功能，通过这个文件，我们可以将编译后的代码映射到源代码，这样就可以在浏览器控制台中看到源代码了。

如下，开启了 source map 后，根据控制台的报错信息，定位到的文件是编译前的代码，并且能够告诉我们具体文件的第几行出错了：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202312061423011.png)

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202312061424398.png)

通过 `devtool` 选项可以开启源代码映射：

```js
module.exports = {
  // webpack 其他配置
  devtool: 'source-map',
};
```

`devtool` 的值除了 `source-map` 之外，还支持以下几个常用选项：

- eval: 每个 module 会封装到 eval 里包裹起来执行，并且会在末尾追加注释 //@ sourceURL.
- source-map: 生成一个 SourceMap 文件.
- hidden-source-map: 和 source-map 一样，但不会在 bundle 末尾追加注释.
- inline-source-map: 生成一个 DataUrl 形式的 SourceMap 文件.
- eval-source-map: 每个 module 会通过 eval() 来执行，并且生成一个 DataUrl 形式的 SourceMap .
- cheap-source-map： 生成一个没有列信息（column-mappings）的 SourceMaps 文件，不包含 loader 的 sourcemap（譬如 babel 的 sourcemap）
- cheap-module-source-map： 生成一个没有列信息（column-mappings）的 SourceMaps 文件，同时 loader 的 sourcemap 也被简化为只包含对应行的。

不通的选项构建速度是不同的，为了达到一个比较好的构建效果，我们通常建议在开发模式下使用 `eval-cheap-module-source-map` 来提升构建速度。在生产环境下使用 `source-map` 来将 source map 文件单独抽离出来，不要让 source map 的代码被打包到源代码中。

## 将开发环境和生产环境进行区分

在编写 webpack 配置时，开发环境和生产环境可能会需要不通的配置。比如在上一节中，我们讲了要在开发环境下使用 `eval-cheap-module-source-map` 而在生产环境下使用 `source-map`。通常我们会使用构建时的系统环境变量来区分生产与开发环境。

我们将 package.json 中的构建脚本进行修改：

```diff
{
  "scripts": {
-   "dev": "webpack serve --config webpack.config.cjs",
+   "dev": "export NODE_ENV=development && webpack serve --config webpack.config.cjs",
-   "build": "webpack --config webpack.config.cjs"
+   "build": "export NODE_ENV=production && webpack --config webpack.config.cjs"
  }
}
```

`export` 指令是 Linux 系统中的一个指令，它可以设置环境变量。比如我们在终端中输入 `export TEST_ENV=1` 这样就设置了一个系统环境变量，我们可以通过 `echo $TEST_ENV` 来输出这个环境变量（但是这个环境变量只在当前终端中生效，新建了一个终端后这个环境变量就不存在了）。

这里我们使用 `export NODE_ENV=development` 与 `export NODE_ENV=production` 来为系统设置了一个 `NODE_ENV` 的环境变量。这意味着，我们在执行 `pnpm dev` 指令时，系统 `NODE_ENV` 环境变量为 `development`，在执行 `pnpm build` 指令时，系统 `NODE_ENV` 环境变量为 `production`。

但是这里存在一个问题，不同的操作环境可能会有不通的指令，比如在 Linux 系统中使用 `export` 指令，而在 Windows 系统中使用 `set` 指令。因此我们需要一个跨平台的指令来设置环境变量，这个指令就是 [cross-env](https://www.npmjs.com/package/cross-env)。

首先安装 cross-env

```sh
pnpm install cross-env -D
```

然后将 `export` 指令替换为 `cross-env` 指令：

```diff
{
  "scripts": {
-   "dev": "export NODE_ENV=development && webpack serve --config webpack.config.cjs",
+   "dev": "cross-env NODE_ENV=development webpack serve --config webpack.config.cjs",
-   "build": "export NODE_ENV=production && webpack --config webpack.config.cjs"
+   "build": "cross-env NODE_ENV=production webpack --config webpack.config.cjs"
  }
}
```

设定完环境变量后，我们在 webpack 配置文件中使用 `process.env.NODE_ENV` 来获取当前的环境变量：

```js
const isDev = process.env.NODE_ENV !== 'production';
```

这样一来，当 `isDev` 为 `true` 时，就代表当前执行的指令是 `pnpm dev` 也就是开发环境；当 `isDev` 为 `false` 时，就代表当前执行的指令是 `pnpm build` 也就是生产环境。通过这个变量我们就可以为 webpack 配置进行一些差异化的配置：

```js
const isDev = process.env.NODE_ENV !== 'production';

module.exports = {
  mode: isDev ? 'development' : 'production', // 根据环境变量设置 mode
  devtool: isDev ? 'eval-cheap-module-source-map' : 'source-map', // 根据环境变量设置 devtool
  module: {
    rules: [
      {
        test: /\.css$/i,
        use: [
          // 在开发环境下使用 style-loader 以提升构建速度，生产环境下使用 mini-css-extract-plugin 插件抽离 css
          isDev ? 'style-loader' : MiniCssExtractPlugin.loader,
          'css-loader',
          'postcss-loader',
        ],
      },
      // ... ...
    ],
  },
  // 其他 webpack 配置
};
```

## 进阶：post-css

[PostCSS](https://postcss.org/) 是一个用 JavaScript 编写的工具，它可以对 CSS 进行处理、转换和优化，如：

- 使用 autoprefixer 为写好的 css 属性自动添加浏览器前缀
- 为 css 添加变量、嵌套、函数等特性
- 使用一些 css 的新特性，同时为旧浏览器提供降级方案

首先，需要安装 postcss 提供 postcss 的核心支持，为了让 webpack 能够成功调用 postcss 还需要安装 [postcss-loader](https://github.com/webpack-contrib/postcss-loader#getting-started)：

```sh
pnpm install postcss postcss-loader -D
```

在 webpack 中添加对应的 loader:

```js
module.exports = {
  // webpack 其他配置
  module: {
    rules: [
      // ... 其他 loader ...
      // 处理 css 文件
      {
        test: /\.css$/i,
        use: [
          MiniCssExtractPlugin.loader,
          'css-loader',
          // 添加 post-css loader
          // 注意：postcss 只能处理 css 代码，因此如果添加使用 saas、less 等 css 预处理器，postcss-loader 要放在对应的预处理器 loader 的前面
          'postcss-loader',
        ],
      },
    ],
  },
};
```

为了使 postcss 生效，还需要在项目的根目录下创建一个 `postcss.config.js` 文件：

```js
module.exports = {
  plugins: [
    // 添加你想使用的插件
  ],
};
```

`postcss-loader` 会自动读取这个文件，但是目前我们尚未配置任何插件，postcss 并不会正产工作。一般情况下，我们只需要引入 [postcss-preset-env](https://www.npmjs.com/package/postcss-preset-env) 即可，这个插件可以将现代 CSS 转换成大多数浏览器都能理解的内容，同时也可以根据目标浏览器或运行时环境添加所需的语法垫片。

首先，我们要安装这个插件：

```sh
pnpm install postcss-preset-env -D
```

然后向 `postcss.config.js` 中添加这个插件：

```js
const postcssPresetEnv = require('postcss-preset-env');

module.exports = {
  plugins: [postcssPresetEnv()],
};
```

默认的，`postcss-preset-env` 提供了缩进语法的特性，我们可以编写带缩进的 css 代码来判断 postcss 是否生效：

```css
.hello {
  background-color: pink;

  a {
    color: pink;
  }
}
```

执行 webpack 构建指令后，查看编译后的代码：

```css
.hello {
  background-color: pink;
}
.hello a {
  color: pink;
}
```

默认情况下，postcss-preset-env 会自动按照 browserslist 的默认兼容策略来编译 css，按照默认策略可以兼容 80% 以上的浏览器。

browserslist 是一个用于专门声明当前项目的目标浏览器的配置文件，如果我们要调整 postcss-preset-env 的默认兼容策略，就可以在项目根目录创建一个 `.browserslistrc` 的文件，并编写对应的配置，如下是一个提供更广泛兼容的配置，它兼容了全世界市场占用率大于 0.5% 的浏览器，并兼容所有主流浏览器（包括已经停止更新的）的最后两个版本：

```txt
> 0.5%, last 2 versions
```

使用了这个配置后你就会发现编译出的代码变得更大了，很多属性都被添加了 css 属性前缀，因为它需要兼容更多的浏览器。

> 你可以在 [browsersl.ist](https://browsersl.ist/#q=defaults) 网站上查看 browserslist 的配置规则

## 进阶：babel

[Babel](https://babeljs.io/) 与 PostCSS 类似，都是一种语言的编译器，PostCSS 负责处理 CSS 而 Babel 负责处理 JavaScript。通过使用 Babel，能够将高级版本的 JavaScript 代码转换为向后兼容的版本，以便能够在老版本的浏览器或环境中运行。

首先，我们要安装 [@babel/core](https://www.npmjs.com/package/@babel/core) 来提供 babel 的核心支持，同时还需要安装 [babel-loader](https://www.npmjs.com/package/babel-loader) 来让 webpack 能够调用 babel：

```sh
pnpm install @babel/core babel-loader -D
```

然后在 webpack 中添加对应的 loader:

```js
module.exports = {
  // webpack 其他配置
  module: {
    rules: [
      // ... 其他 loader ...
      // 处理 js 文件
      {
        test: /\.(?:js|mjs|cjs)$/, // 匹配 js、mjs、cjs 后缀的文件
        exclude: /node_modules/, // 从 node_modules 引入的 js 代码不需要 babel 参与编译（因为大多数包已经被编译好了）
        use: {
          loader: ['babel-loader'],
        },
      },
    ],
  },
};
```

为了使 babel 生效，与 PostCSS 类似的，我们需要一个 babel 的配置文件，在项目的根目录下创建一个 `babel.config.js` 文件：

```js
module.exports = {
  presets: [
    // 添加你想使用的预设
  ],
};
```

可以发现，Babel 的配置文件与 PostCSS 的配置文件是类似的，因为它们的工作原理都是本身提供一个核心库的支持，而具体的工作则需要对应的插件来完成，因此我们需要安装对应的插件。

在没有什么其他需求的情况下，我们可以安装 [@babel/preset-env](https://www.npmjs.com/package/@babel/preset-env) 插件来提供一个较为全面的预设配置，改配置可以将现代 JavaScript 代码转换为向后兼容的版本，以便能够在老版本的浏览器或环境中运行。

首先我们安装该插件：

```sh
pnpm install @babel/preset-env -D
```

然后在 `babel.config.js` 中添加该插件：

```js
module.exports = {
  presets: [
    [
      '@babel/preset-env',
      {
        // preset config
      },
    ],
  ],
};
```

还记得在上一步我们编写的 browserslist 配置吗？`@babel/preset-env` 同样会根据它来生成对应目标的兼容代码。

当我们执行 webpack 编译指令后，可以发现编译出的代码中，箭头函数、const、let 等新特性都被转换成了 ES5 的代码。以 [可选链运算符](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Operators/Optional_chaining) 为例子，原代码如下：

```js
const o = { a: 123 };
console.log(o?.a ?? 'nothing');
```

为了兼容大部分的浏览器，babel 将可选链操作符进行转换为三元运算符，得出编译后的代码为：

```js
console.log(
  null !== (n = null == a ? void 0 : a.a) && void 0 !== n ? n : 'nothing',
);
```

很多人 babel 配置到这里就觉得万事大吉了，但实际上编译出来的代码并没有按照预想的那样去兼容到低版本浏览器。因为 babel 只会转换新的 JavaScript 语法，但是不会转换新的 API，也就是说，Babel 可以将你的箭头函数、const、let 等新语法转换成 ES5 的代码，但是它不会将 Promise、Array.from、Object.assign 等新的 API、对象转化为 ES5 环境可用的代码。

因此我们如果想要让 ES5 环境的浏览器支持这些新的 API，就需要去实现它们，这种实现被称为 polyfill（语法垫片）。@babel/preset-env 支持引入需要的 polyfill，但是 preset-env 并没有这些 polyfill 的实现，因此我们需要安装 [core-js](https://www.npmjs.com/package/core-js)，core-js 是一个提供了大量 polyfill 的库，它的 polyfill 覆盖了 ES5、ES6、ES7、ES8、ES9、ES10、ES11、ES12 等所有的 ECMAScript 标准。

```sh
pnpm install core-js
```

然后，需要在 `babel.config.js` 中添加 `core-js` 的配置：

```js
module.exports = {
  presets: [
    [
      '@babel/preset-env',
      {
        corejs: 3, // 指定 core-js 版本
        useBuiltIns: 'usage', // 按需引入 polyfill
      },
    ],
  ],
};
```

运行构建指令后，我们会发现构建产出大了很多，这是因为 babel 从 core-js 引入了当前项目所需要的 polyfill。

> 在决定是否使用 core-js 时，一定要考虑到你的项目是否真的需要这些 polyfill，比如项目如果使用 Vue3，那么就不需要引入大量为了兼容 ES5 环境的 polyfill，因为 Vue3 本身就是基于 ES6 环境开发的。

但是此时还存在两个问题需要解决：

1. babel 会将 core-js 的 polyfill 还有一些 helper 函数打包到每个文件中，这样会导致每个文件都包含了重复的代码，从而导致打包后的文件体积变大。
2. babel 引入的 polyfill 函数会污染全局环境，这样会导致全局环境中存在大量的 polyfill 函数，这些函数可能会与其他库冲突。

为了解决这两个问题，我们需要安装 [@babel/plugin-transform-runtime](https://www.npmjs.com/package/@babel/plugin-transform-runtime) 插件（需要 @babel/runtime 支持），它会将 babel 重复引用的函数转换为 runtime 函数，从而解决上面的问题，并减少打包后的文件体积。

```sh
pnpm install @babel/plugin-transform-runtime @babel/runtime -D
```

然后在 `babel.config.js` 中添加该插件：

```js
module.exports = {
  presets: [
    [
      '@babel/preset-env',
      {
        corejs: 3, // 指定 core-js 版本
        useBuiltIns: 'usage', // 按需引入 polyfill
      },
    ],
  ],
  plugins: ['@babel/plugin-transform-runtime'],
};
```