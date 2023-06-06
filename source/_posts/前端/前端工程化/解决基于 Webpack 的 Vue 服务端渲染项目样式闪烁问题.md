---
title: 基于 Webpack 的 Vue 服务端渲染项目提前加载当前页面所需资源
tags:
  - Webpack
  - Vue
  - SSR
categories:
  - 前端
  - 前端工程化
date: 2023-06-06 15:29:59
---
# 前言

当我们使用 Webpack 搭建一个基于 Vue 的服务端渲染项目时，通常会遇到一个很麻烦的问题，即我们无法提前获取到当前页面所需的资源，从而不能提前加载当前页面所需的 CSS，导致客户端在获取到服务端渲染的 HTML 时，得到的只有 HTML 文本而没有 CSS 样式，之后需要等待一会儿才能将 CSS 加载出来，也就是会遇到『样式闪烁』这样的问题。

# 问题分析

这是由于 webpack 应用的代码加载机制导致的。 在大型应用中，webpack 不可能将项目只打包为单独的一个 js、css 文件，而是会利用 webpack 的 [代码分割](https://webpack.docschina.org/guides/code-splitting/) 机制，将庞大的代码按照一定的规则（比如超过一定的大小、或者被多次引用）进行拆分，这样代码的产出就会成为如下的样子：

> 注：`xxx` 指的是每次打包生成的文件哈希，用于更新浏览器的本地缓存，更多详情参考 [官方文档](https://webpack.docschina.org/guides/caching/)

```
// 入口文件
main.xxx.js
main.xxx.css

// runtime 文件，后续重点介绍
runtimechunk~main.xxx.js

// 使用了异步加载方式引入而被拆分的包，如 vue-router 的路由懒加载
layout.xxx.js
layout.xxx.css
home-page.xxx.js
home-page.xxx.css
user-page.xxx.js
user-page.xxx.css

// 被拆分的子包（如果被拆分的子包中没有 css 文件的引入，那么就不会生成 css 子包）
73e8df2.xxx.js
73e8df2.xxx.css
980e123.xxx.js
```

如上，如果没有进行特殊的 webpack 分包配置，一般就会生成如上四种类型的包，并且如果使用了 `css-minimizer-webpack-plugin` 的话（PS：这个包是必须的），还会为每个引用了 css 的子包再单独生成一个对应的 css 文件。这四种类型的包在整体上还可以被具体划分为两类：

- 具名子包（namedChunk）
- 随机命名子包

`main.xxx.js` 这种入口文件，以及 `home-page.xxx.js` 这样异步引入同时并使用 [MagicComments](https://webpack.docschina.org/api/module-methods/#magic-comments) 进行命名的包，被称为『具名子包』；而类似 `73e8df2.xxx.js` 这种文件名是由一串随机哈希组成的文件，我们将其称为『随机命名子包』。

通常这两种包是存在依赖关系的，随机命名子包其实就是从命名子包中拆分出来的代码，或者是多个命名子包共用的某一部分代码，依赖关系示例如下：

![](https://s2.loli.net/2023/06/06/mwkFKRT7cilXpYb.png)

当我们打包好一个 Vue 应用之后，假设 chunk 之间的依赖关系如上图所示，打包好的 HTML 会按顺序内联入如下几个 js 和 css：

- runtimechunk~main.js
- 73e9df.js
- 29fe22.js
- mian.js
- main.css

`mian.js` 被内联入 HTML 的原因是因为其是当前 Vue 应用的入口文件，不论用户访问哪个页面都会加载，因此必须被内联到 HTML 中；`73e9df.js`、`29fe22.js` 这两个文件被内联入 HTML 的原因是因为他们属于 `main.js` 的依赖 chunk，vue 相关的代码就很可能被打包到这两个子包中，`main.js` 如果想要正常运行就必须要先加载这两个包；`main.css` 被内联到 HTML 的原因是因为 `main.js` 中引用了一些 css，这些 css 也会被视作应用加载的必要加载项。

最特殊的是 `runtimechunk~main.js` 这个文件，这个文件的加载优先级是最高的，然而这个文件其实既不属于具名子包，也不属于随机命名子包，它的作用更像是一份清单文件，记录了具名子包与随机命名子包之间的关系，并包含了一些运行时代码，得以能够成功加载出当前页面所需要的静态资源文件。

举例来说，chunk 之间的依赖关系仍用上图表示，当用户访问了这个 Vue 应用的首页，并且当前项目的 vue-router 使用了路由懒加载，其路由声明如下：

```js
const HomePage = () => import(/* webpackChunkName: "home-page" */ './views/HomePage.vue') // 会生成 home-page.js 这个子包

const router = createRouter({
  // ...
  routes: [{ path: '/home', component: HomePage }],
})
```

当浏览器访问当前页面后，首先会下载所有的内联资源，这些内联资源的 script 标签被设置为 `defer`，也就是不会阻塞页面的渲染，此时浏览器会在现在这些资源的同时将 SSR 渲染得出的 HTML 页面直接渲染到浏览器中，这时用户将看到一个只包含了部分样式的页面（部分样式指的是 main.css 中包含的样式），如下：

![](https://s2.loli.net/2023/06/06/gWZweErqaxvG3FL.png)

当内联资源下载完成后会率先运行 `runtimechunk~main.js` 文件，runtimechunk 的运行时代码就会协调加载并运行 `main.js` 及其依赖。当 `mian.js` 执行到 vue-router 中的代码时，就会去加载 HomePage 组件的代码，此时会根据 runtimechunk 中的代码清单查询到需要加载 home-page.js 文件，此外还会查询 home-page.js 文件的依赖 chunk，并找到 22e9df.js、79fe223.js、2312e2.js 这些 js 文件以及 22e9df.css、79fe223.css、2312e2.css、home-page.css 这些 css 文件，为这些文件生成 script 和 link 标签，将其使用 `appendChild` 的方式添到 HTML 的 head 中并进行加载（js 文件加载完成后会自动移除掉 script 标签，而 link 标签是不会被移除的）。

直到此时，当浏览器将 22e9df.css、79fe223.css、2312e2.css、home-page.css 这几个首页相关的 css 文件成功下载下来之后，首页的样式才会被完全加载。这个过程是很明显会被用户刚知道的，这也就是 SSR 项目中样式闪烁问题存在的原因。

# 解决问题

经过上面的分析，我们不难发现样式闪烁的原因就是因为在页面没有加载首页样式前就已经渲染了 HTML，那么我们解决问题的思路就是要在服务端渲染时将服务端渲染的 HTML 中内联入当前页面所需要的 CSS 文件，这样在 HTML 渲染到页面前，会被内联的 CSS 阻塞，必须等待 CSS 加载成功后才能进行渲染，而此时渲染出的就是一个有了样式的页面。

那么难点来了，当用户访问某个页面时，我们如何在服务端渲染时就得知当前页面所需的 CSS 文件呢？

## 简单推断

我们先来简单推断一下，首先我们不需要管 `main.css`，因为其已经内联到模板 HTML 中了，那么假如用户访问了网站首页，因为我们用了 webpack 的 Magic Comments，可以得知首页组件的 JS 代码是打包在 `home-page.js` 中的，那么对应的，首页相关的 CSS 代码是打包在 `home-page.css` 这个具名子包中的，因此我们可以简单的写一个判断：当用户访问首页路由的时候，在返回给客户端的 HTML 中为其添加一个 link 标签，让其加载 `home-page.css`，代码示例如下：

HTML 模板：

```html
<!DOCTYPE html>
<html>

<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width,initial-scale=1.0">
    <%= htmlWebpackPlugin.tags.headTags %>
    <!-- preload-links -->
</head>

<body>
    <div id="app"><!-- app-html --></div>
</body>

</html>
```

路由：

```js
// router.js
const router = createRouter({
  // ...
  routes: [
	  {
		  path: '/',
		  component: import(/* webpackChunkName: "layout" */ './components/layout/index.vue'),
		meta: {
			// 在此指定一下当前组件打包的 chunkName
			chunkName: 'layout'
		},
		children: [
			{
				path: '/home',
				component: import(/* webpackChunkName: "home-page" */ './views/HomePage.vue'),
				meta: {
					chunkName: 'home-page',
				}
			} 
		]
	  },
  ],
})
```

服务端渲染逻辑（简化版）：

```js
// entry.server.js
import {createSSRApp as createApp, renderToString} from 'vue';
import router from './router';

async function createSSRApp() {
	const app = createApp();
	app.use(router);
	await router.isReady();
	const appContent = await renderToString(app);
	return {
		appContent,
		router,
	}
}
```

```js
// server.js
const { appContent, router } = createSSRApp()

// 判断当前页面应该加载的 js
function getPreloadLinkByChunkNames(chunkNames) {
	const PUBLIC_PATH = '/';
	const CSS_ASSET_PATH = 'assets/css/';
	const cssAssets = chunkNames.map(
		name => `${PUBLIC_PATH}${CSS_ASSET_PATH}name.css`
	);
	const links = cssAssets.map(asset => {
		if(assets.endsWith('.css')) {
			// preload 能够使页面更快的加载 css 资源
			return `<link rel="preload" as="style" href="${file}" >`
				+ `<link rel="stylesheet" as="style" href="${file}">`;
		}
	});
	return links;
}

/**
 * 根据路由的 meta 获取当前页面的具名 chunk
 * 比如当用户访问 `/home` 页面，根据上面路由的定义
 * currentPageChunkNames 得到的值就是 ['layout', 'home-page']
 */
const currentPageChunkNames = router.currentRoute.value.matched.map(
	item => item.meta?.chunkName
);
const preloadLinks = getPreloadLinkByChunkNames(currentPageChunkNames);

// 读取模板
const template = fs.readFileSync(/** ... ... */)
const html = template.toString()
	.replate('<!-- preload-links -->', ${preloadLinks})
	.replace('<!-- app-html -->', `${appContent}`);
// 向客户端发送渲染出的 html
res.send(html)
```

这样，当浏览器拿到服务端渲染出的 HTML，就可以加载出来首页『主要』的 CSS 了，我们可以看下现在的效果 ：

![](https://s2.loli.net/2023/06/06/o1ZEpsXeYlrfT4b.png)

之所以说『主要』 的 CSS 已经加载出来了，那么就肯定有部分『次要』的 CSS 没有加载出来，那么这一部分 CSS 为什么没有加载出来呢？

## 加载完整的 CSS

也许你已经发现了，到目前为止，我们仅仅把『具名子包』的 CSS 引入仅了服务端渲染出的 HTML 中，但是『具名子包』所依赖的『随机命名子包』我们还没有内联进去，而这些『随机命名子包』中的样式可能是某些公共组件的通用样式，亦或者是你使用的第三方组件库的样式，这些样式因为可能被多个页面引用到，所以 webpack 会将其拆分成多个子包，让多个页面都引用同一个子包。

到这里我们似乎遇到了一个难点，那就是如何获取到这些命名没有规律且有可能被其他页面共享的『随机命名子包』。

还记得前面提到的 runtimechunk 吗？既然 webpack 可以生成 runtimechunk 来记录每个子包之间的依赖关系，那么是否有一种方法可以在服务端渲染时候获取到这个关系，即当我们知道了当前页面加载的具名子包是 `home-page`，顺着这个依赖关系，我们就可以找到 `22e9df.css` 和 `79fe223.css` 这两个被拆分为随机命名子包的样式。

[webpack-stats-plugin](https://www.npmjs.com/package/webpack-stats-plugin) 就提供了这样的能力，利用这个 webpack 插件，通过合理的配置我们可以生成一个 `stats.json` 这个文件记录了所有的具名子包（namedChunk）以及这些具名子包的依赖，这样就解决了我们上面遇到的难题。

在 webpack 中写入配置：

```js
export default {
	target: 'web',
	entry: 'xxx',
	output: {
		// ... ...
	},
	module: {
		rules: [
			// ... ...
		]
	},
	plugins: [
		// ... ...
		new StatsWriterPlugin({
            filename: 'stats.json',
            fields: ['publicPath', 'namedChunkGroups'],
        }),
	],
	// ... ...
}
```

> `fields` 可以支持 `["errors", "warnings", "assets", "hash", "publicPath", "namedChunkGroups"]`，更多配置可以查看 [官方示例](https://github.com/FormidableLabs/webpack-stats-plugin/blob/main/test/scenarios/webpack5/webpack.config.js)
