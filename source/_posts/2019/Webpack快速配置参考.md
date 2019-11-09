---
title: Webpack快速配置参考
date: 2019-05-15 22:03:54
tags: [Webpack]
categories:
  - Front
  - 构建工具
---
# 1. 安装与设置项目目录结构

安装基础的webpack组件：

```shell
mkdir webpack-demo 
cd webpack-demo
npm init -y
npm install webpack webpack-cli --save-dev
```

常用目录参考：

```
webpack-demo 
|- /node_modelues
|- /dist（存放最终输出的文件）
|- /asset（存放HTML模板以及favoicon）
   |- index.html
|- /src（存放源码）
   |- index.js（入口文件）
   |- /js
   |- /css
   |- /img
|- package.json
|- package-lock.json
|- webpack.common.js（webpack通用配置项）
|- webpack.dev.js（webpack开发环境配置项）
|- webpack.prod.js（webpack生产环境配置项）
```

# 2. 安装开发环境依赖

```shell
npm install clean-webpack-plugin html-webpack-plugin webpack-dev-server webpack-merge -D

npm install sass-loader node-sass style-loader css-loader file-loader -D
```

简单介绍：
- clean-webpack-plugin： 用于每次编译代码时，自动清除目录中的dist文件夹
- html-webpack-plugin：与 clean-webpack-plugin 配合使用，可以自动生成 dist 中的 html 文件，并且通过配置可以自动导入 webpack config 中的所有 entry 文件。
- file-loader：文件加载器
- webpack-dev-server：webpack 开发环境服务器
- webpack-merge：自动合并 webpack config 的生产环境配置和开发环境配置

# 3. 具体配置

## 3.1 package.json文件

在 package.json 文件下编写 `scripts`，来快捷在 npm 环境下运行 webpack 指令：

```json
{
  "name": "app-name",
  "version": "1.0.0",
  "description": "",
  "private": true,
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1",
    "build": "webpack --config webpack.prod.js",
    "start": "webpack-dev-server --open --config webpack.dev.js"
  },
  "author": "",
  "license": "ISC",
  "devDependencies": {
    ... ...
  },
  "dependencies": {
    ... ...
  }
}
```

## 3.2 webpack config文件

使用 webpack config 多环境配置文件，可以让 webpack 在不同的编译状态下实施相对应的编译模式，如：

- 在 `npm run dev` 模式下执行的是 `webpack.common.js` + `webpack.dev.js` 的设置；
- 在 `npm run build` 模式下执行的是 `webpack.common.js` + `webpack.dev.js` 的设置。

合并配置文件依赖于 `webpack-merge` 插件

### webpack.common.js

webpack 的基础配置文件，将开发环境和生产环境的配置同样的项目写在该文件下：

```javascript
const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const { CleanWebpackPlugin } = require('clean-webpack-plugin')
const webpack = require('webpack');

module.exports = {
  entry: './src/index.js',
  output: {
    filename: 'bundle.js',
    path: path.resolve(__dirname, 'dist')
  },
  plugins: [
    new CleanWebpackPlugin(),
    new HtmlWebpackPlugin({
      title: 'Title',
      template: './asset/index.html' // HtmlWebpackPlugin 自动生成 HTML 文件的模板
    }),
    new webpack.HotModuleReplacementPlugin()
  ],
  module: {
    rules: [
      // 图片加载器
      {
        test: /\.(png|svg|jpg|gif)$/,
        use: [{
          loader: 'file-loader',
          options: {
            name: '[hash].[ext]', // 将图片以哈希值命名，如果需要使用原名则将 [hash] 改为 [name]
            outputPath: 'images' // 将读取的图片放置在 dist/images/ 目录下
          }
        }]
      },
      // css加载器
      {
        test: /\.css$/,
        use: [
          'style-loader',
          'css-loader'
        ]
      },
      // scss加载器
      {
        test: /\.scss$/,
        use: [
            "style-loader",
            "css-loader",
            "sass-loader"
        ]
      }
    ]
  }
};
```

### webpack.dev.js

开发环境配置，主要配置热更新以及源代码映射：

```javascript
const merge = require('webpack-merge');
const common = require('./webpack.common.js');


module.exports = merge(common, {
  mode: 'development',
  devtool: 'inline-source-map',
  devServer: {
    contentBase: './dist',
    hot: true
  }
})
```

### webpack.prod.js

生产环境配置：

```javascript
const merge = require('webpack-merge');
const common = require('./webpack.common.js');


module.exports = merge(common, {
  mode: 'production'
})
```

# 4. 编译

运行开发模式：

```sh
npm run dev
```

运行构建模式：

```sh
npm run build
```