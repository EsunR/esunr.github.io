---
title: 搭建服务端渲染应用时的 Webpack 分包策略
tags:
  - Webpack
categories:
  - 前端
  - 前端工程化
date: 2023-05-23 18:41:27
---
# 为什么要分包

当搭建的应用注重用户打开速度时，合理的分包策略有助于减少用户首屏加载应用时加载的资源数量，并且对于部分资源可以复用，避免重复加载，从而提升用户体验。

举例来说，使用 webpack 进行合理的分包可以达到如下效果，比如：

- 让项目的分包体积更小，充分利用浏览器并行加载的能力，避免加载过大的 chunk。
- 当前项目是基于 vue 的，如果按照默认的分包策略，项目每次更新后都会生成新的 main.js，main.js 中又包含了 vue 的代码，相当于每次项目更新，用户都要重新下载一遍 vue 的代码，这是没有必要的。通过改写分包策略，可以将 vue 相关的代码单独生成一个包，将其缓存到客户端后，后续的每次应用更新就不需要客户端下载重复的代码。
- 剥离 ElementPlus 相关的代码，使得在 SSR 时可以预加载 ElementPlus 的样式，避免样式闪烁。

# 使用动态导入

webpack 提供了 [动态导入(dynamic import)](https://webpack.docschina.org/guides/code-splitting/#dynamic-imports) 功能来实现了可以在应用运行时懒加载一些 JS 代码。

## 示例 1：懒加载 SDK

比如，当我们使用一个比较大的第三方 SDK 时，如百度云的 Bos 文件上传 SDK，如果我们不做任何优化，那么 webpack 会将这个 SDK 打包到应用的主包中，那么就会导致用户无论用户是否有用到文件上传的功能，在页面加载时都会去下载百度云的文件上传 SDK，那么这个下载行为既会浪费带宽，又会阻塞页面的渲染，使用户的白屏时间加长。

为了避免这个问题，我们就可以通过使用 webpack 的动态导入功能，让用户点击『上传』按钮时，再去加载文件上传的 SDK，这样就真正坐到了按需加载，示例代码如下：

```ts
const loadBaiduCloudSdk = () => import(/* webpackChunkName: "baiducloud" */ '@baiducloud/sdk');

uploadBtnEl.addEventListener('click', async () => {
	const {BosClient} = await loadBaiduCloudSdk();
	new BosClient({
		// ... ...
	})
})
```

这里我们使用了 [magic comment](https://webpack.docschina.org/api/module-methods/#magic-comments) 的 webpackChunkName 来显式指定了 webpack 打包的 JS 代码块的名称，当构建完成后，如果我们的 `chunkFilename` 定义的为 `[name].[contenthash:8].js` ，那么我们就会发现构建产出中为 Bos SDK 单独生成了一个 `baiducloud.xxxxxxxx.js` 的文件。在 Chrome DevTool 中的 network 面板中可以看到，当用户点击上传按钮后浏览器才会下载这个 chunk：

![](https://s2.loli.net/2023/05/24/whaftINZkbYGWpD.png)

## 示例 2：Vue 按需加载 i18n 语言包

如果应用需要多语言功能，那么只有当用户访问对应语言版本的网站时才需要加载这个网站的语言包，而不是一次性加载所有的语言包，利用 webpack 动态导入我们可以实现这一点。

我们的文件结构如下：

```
lang
  ├── en-US.ts
  ├── zh-CN.ts
  ├── ar.ts
  ├── ur.ts
  └── ... ...
```

```ts
// en-US.ts
export default {
	hello: 'Hello',
	word: 'Word'
}
```

我们编写一个 `loadLang` 函数：

```ts
// en-US 不进行懒加载，因为其作为 FALLBACK_LANG 是必须加载的
import messageSchema from './lang/en-US';

const FALLBACK_LANG = 'en-US';

export async function loadLang(i18n: I18n, lang: string) {
    const messages = await import(/* webpackChunkName: "locale-[request]" */ `./lang/${lang}.ts`);
    // set locale and locale message
    i18n.global.setLocaleMessage(locale, messages.default);
    // set fallback langs
    i18n.global.setLocaleMessage(FALLBACK_LANG, messageSchema);
}
```

当页面加载时，我们按照页面路径来为用户按需加载语言：

```ts
// app.ts
const i18n = createI18n({locale, legacy: false, fallbackLocale: FALLBACK_LANG});

// 以 vue router 的路由守卫为示例，在加载页面前去下载对应的语言包
router.beforeEach(async (to, _from, next) => {
	const pathname = window.location.pathname;
    let lang = pathname.split('/')[1];
	// set i18n
	await loadLocaleMessages(i18n, lang);
	setI18nLanguage(i18n, lang);
	return next();
});

app.use(i18n)
```

我们可以通过 webpack-bundle-analyzer 看出，所有的语言都被 webpack 单独打包为了一个独立的 JS，如：

![](https://s2.loli.net/2023/05/24/oQCl43qRxGEkO8b.png)

当用户访问对应的语言时（除了 en-US，因为其作为 FALLBACK_LANG 会始终被加载），对应的语言包才会被加载。

## 示例 3：vue-router 路由懒加载

vue-router 的路由懒加载实际上也是动态导入的一种应用：

```js
// 将
// import UserDetails from './views/UserDetails.vue'
// 替换成
const UserDetails = () => import('./views/UserDetails.vue')

const router = createRouter({
  // ...
  routes: [{ path: '/users/:id', component: UserDetails }],
})
```

如果使用了 webpack，可以使用命名 chunk：

```js
const UserDetails = () =>
  import(/* webpackChunkName: "group-user" */ './UserDetails.vue')
const UserDashboard = () =>
  import(/* webpackChunkName: "group-user" */ './UserDashboard.vue')
const UserProfileEdit = () =>
  import(/* webpackChunkName: "group-user" */ './UserProfileEdit.vue')
```

# 使用 optimization.splitChunks

Webpack 提供了 `optimization.splitChunks` 选项来提供给开发编写一些自定义的分包策略。对于普通的开发者来说，Webpack 的默认分包策略已经足够，其默认分包策略为：

* 新的 chunk 可以被共享，或者模块来自于 `node_modules` 文件夹
* 新的 chunk 体积大于 20kb（在进行 min+gz 之前的体积）
* 当按需加载 chunks 时，并行请求的最大数量小于或等于 30
* 当加载初始化页面时，并发请求的最大数量小于或等于 30

借助这个配置项，我们可以更细化的配置项目的产出。

## 示例 1：单独打包 vue 文件

假设我们在使用 webpack 编写一个 vue 项目，那么通常 vue 的版本在每次迭代应用版本后通常是不会发生改变的，如果我们可以将 vue 相关的代码打包成一个包，并利用浏览器缓存缓存起来这个包，那么在应用每次迭代后，客户端就能尽可能的少产生新的文件变更，网站加载就不会因为频繁迭代上线而让客户端需要频繁下载之前已经缓存好的资源。

利用 `splitChunks` 我们利用文件名匹配的方式来获取到 vue 相关的代码，并将其打包成一个 `vue-bundle.[hash].js` 这样的文件：

```js
optimization: {
	splitChunks: {
		chunks: 'all',
		minSize: 30000,
		maxAsyncRequests: 5,
		cacheGroups: {
			vue: {
				// 优先级
				priority: 20,
				test: /[\\/]node_modules[\\/](vue|vue-router|vuex)[\\/]/,
				name: 'vue',
				chunks: 'all'
	        },
	        // ... ...
		},
	},
},
```

> `optimization.splitChunks.chunks` 其默认值为 `async` ，即只为使用了异步导入方式（即动态导入）引入的包才会被拆分为一个单独的 js。设置为 `all` 后，webpack 会尝试对所有的代码块进行拆分，包括同步引入的代码，即使是单入口文件，只要文件超出一定的体积、被多个文件引用一定次数或其他限定条件时，就会被拆分成子包。

## 示例 2：单独打包 ElementPlus 的 CSS 样式

在 web 应用加载时，如果遇到 CSS 文件会阻塞页面的渲染，尤其是对于一个使用了 Vue 或 React 框架的项目来说，在页面加载时，通常会加载一个 runtime 文件来获取当前页面的依赖，然后再去拉取当前页面需要 JS 和 CSS，这样就使得页面白屏时间更长了。

那么倘若我们能够提前加载好某些 CSS，整个页面的白屏时长必定会减少一些，尤其是对于 SSR 的项目来说，提前加载 CSS 是非常有必要的。

以 ElementPlus 为例，我们可以单独将 ElementPlus 的样式给打包成一个 CSS 文件，并将其写入到 HTML 模板中，这样在页面加载时，并且在 runtime 执行前就能提前加载 ElementPlus 组件的样式了，减少了资源加载的等待时长。

> 如果项目在入口就引用到了 ElementPlus，那么 `html-webpack-plugin` 生成的 HTML 文件中就会自动加上 ElementPlus 的 css 文件。

代码示例如下：

```js
optimization: {
	splitChunks: {
		chunks: 'all',
		minSize: 30000,
		maxAsyncRequests: 5,
		cacheGroups: {
			elementPlus: {
				// 优先级
				priority: 20,
				test: /[\\/]node_modules[\\/]element-plus(.*)/,
				name: 'element-plus',
				chunks: 'all',
				// 指定这条策略只对 css 生效
				type: "css/mini-extract",
				enforce: true,
	        }
	        // ... ...
		},
	},
},
```

注意：如果要只单独打包 css，是需要借助 `mini-css-extract-plugin` 插件来实现的，因为这个插件是用于将引入的 css 进行拆分并打包成单独的 css。只有使用了这个插件，`cacheGroups` 中的 `type` 才会有 `css/mini-extract` 这个值（[参考](https://github.com/webpack-contrib/mini-css-extract-plugin#extracting-all-css-in-a-single-file)）。

> 除了 type 为 `css/mini-extract` 之外，还可以设置 `auto/javascript` 来将 cacheGorup 规则单独应用为 js 文件上，而 CSS 走默认的规则。