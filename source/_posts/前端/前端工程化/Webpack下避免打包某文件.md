---
title: Webpack下避免打包某文件
tags:
  - webpack
categories:
  - 前端
  - 前端工程化
date: 2020-03-31 20:49:23
---

在使用 Webpack 进行前端项目的编写时，对于某些全局变量，如后台 API 的 BaseUrl 通常是需要可配置的。这些配置在 webpack 中如果更改之后往往需要重新打包编译，所以我们需要将配置文件抽离出来，不让 webpack 对其进行打包编译，这样就可以修改编译后的项目配置了。

首先我们要在项目 src 根目录创建一个 config.js 文件，作为配置文件写入：

```js
// config.js
window.sysConfig = {
  apiBaseUrl: "http://47.104.211.178:9189"
}
```

然后再 webpack 配置中引入 `copy-webpack-plugin` 插件，对其进行配置：

```js
plugins: [
  // ... ...
  new CopyWebpackPlugin([
    {
      from: path.resolve(__dirname, "src/config.js"),
      // to: ""
    }
  ])
],
```

这样就能免除 `config.js` 被打包，同时我们再项目 html 模板中引入该文件：

```html
<script src="./config.js"></script>
```

这样，使用全局配置文件时就可以使用：

```js
console.log(window.sysConfig.apiBaseUrl); // "http://47.104.211.178:9189"
```