---
title: ElementPlus Webpack 下按需引入
tags:
  - Webpack
  - Vue
  - Element-Plus
categories:
  - 前端
  - Vue
date: 2022-07-05 19:40:57
---
# 1. 引入方案

官方说明：[链接](https://element-plus.gitee.io/zh-CN/guide/quickstart.html#%E6%8C%89%E9%9C%80%E5%AF%BC%E5%85%A5)

我们需要在 Webpack 配置里添加两个 Plugin：

```js
import autoImport from 'unplugin-auto-import/webpack';
import components from 'unplugin-vue-components/webpack';
import {ElementPlusResolver as elementPlusResolver} from 'unplugin-vue-components/resolvers';

// ... ...
plugins: [
	autoImport({
		resolvers: [elementPlusResolver()],
	}),
	components({
		resolvers: [
			elementPlusResolver(),
		],
	}),
],
```

## 1.1 unplugin-auto-import

> https://github.com/antfu/unplugin-auto-import

`autoImport` 是用来帮助我们自动引用 Element 组件的，当你在 vue 组件里编写入：

```html
<template>
	<el-button>你这瓜多少钱一斤</el-button>
</template>

<script lang="ts">
export default defineComponent({
    setup() {
        return {};
    },
});
</script>
```

那么经过编译后，`autoImport` 会自动帮我们吧 ElButton 组件给引入，那么代码就会成为：

```html
<template>
	<el-button>你这瓜多少钱一斤</el-button>
</template>

<script lang="ts">
import "ElButton" from "element-plus"

export default defineComponent({
    setup() {
        return {};
    },
});
</script>
```

但这时候代码还不能使用，因为 `defineComponent` 的 `components` 中还没有定义 ElButton 组件，此时我们就需要使用 unplugin-vue-components

## 1.2 unplugin-vue-components

> https://github.com/antfu/unplugin-vue-components

unplugin-vue-components 导出的 `components` 可以帮我们自动定义组件中用到的子组件，承接前面的代码，使用了 unplugin-vue-components 后，代码就会被编译为：

```html
<template>
	<el-button>你这瓜多少钱一斤</el-button>
</template>

<script lang="ts">
import "ElButton" from "element-plus"

export default defineComponent({
	component: {
		ElButton
	},
    setup() {
        return {};
    },
});
</script>
```
 
 但是此时只是导入了组件，组件的样式还没有被引入，这时候就需要 unplugin-vue-components/resolvers 下导出的 `ElementPlusResolver` 了。
 
 `ElementPlusResolver` 提供了组件标签和组件引入位置的映射关系，因此我们需要将其作为 resolver 传入前面提到的`autoImport` 和 `componet` 两个插件中，这样两个插件才知道我们在 template 里面写的组件标签需要引用到哪些组件，然后来帮我们引入和声明。
 
 除此之外，`ElementPlusResolver` 还可以帮我们自动引入组件的样式，通过配置它的 `importStyle` 配置项，我们还可以禁用这个功能，或者让其引入 css 文件（默认）或者 scss 文件。
 
 使用了 `ElementPlusResolver` 后，代码就会被编译为：
 
 ```html
 <template>
	<el-button>你这瓜多少钱一斤</el-button>
</template>

<script lang="ts">
import "ElButton" from "element-plus"
import 'element-plus/es/components/button/style/css'

export default defineComponent({
	component: {
		ElButton
	},
    setup() {
        return {};
    },
});
</script>
 ```
 
此外，在项目里如果你的一些全局组件放在 `src/components` 目录下，当你在其他组件中使用时，unplugin-vue-components 也会自动将这些组件自动引入并声明。

同时 unplugin-vue-components 自动导入的组件也是支持 typescript 的，将 `component` 插件的 `dts` 属性设置为 true 后，会在项目根目录生成一个 `components.d.ts` 文件，如果你的编辑器使用了 volar，并且把这个 dts 文件添加 tsconfig 文件之后，在使用这些被自动引入的组件时便会出现 ts 提示。

> 这里不建议将业务组件也完全依赖自动引入，因为不同模块间的业务组件可能存在同名情况。

# 2. 按需引入时，如何自定义样式

自定义相关的样式，ElementPlus 官网的说明很少，但是从源码里可以翻到一个 README：https://github.com/element-plus/element-plus/blob/1.1.0-beta.20/docs/en-US/guide/theming.md

按照上面的说明我们需要创建一个样式文件，并将其放在 `stlye/element-variable.scss` 目录下：

```scss
// README: https://github.com/element-plus/element-plus/blob/1.1.0-beta.20/docs/en-US/guide/theming.md
@forward "element-plus/theme-chalk/src/common/var.scss" with (
	// 注意：1.2.0+ 移除了 IconFont，不要按照原文 Demo 中添加 $font-path 变量
    // $font-path: '~element-plus/dist/fonts',
    // 主题颜色
    $colors: (
        'primary': (
            'base': #303CB9,
        ),
        'success': (
            'base': #67c23a
        ),
        'warning': (
            'base': #e6a23c
        ),
        'danger': (
            'base': #ed3637
        ),
        'error': (
            'base': #f56c6c
        ),
        'info': (
            'base': #909399
        ),
    ),
    // 字体颜色
    $text-color: (
        'primary': #1D2024,
        'regular': #505255,
        'secondary': #C0C4CC,
        'placeholder': #C0C4CC,
    )
);
// 因为我们采用按需引入方式来引入组件，因此不要全局引入样式文件
// @use "~element-plus/theme-chalk/src/index";
```

然后在 Vue 入口文件 main.ts 里引入：

```ts
import "@/stlye/element-variable.scss"
```

之后我们便会发现，并没有什么用 ... ... 定义的变量并没有生效。

其实经过分析 unplugin-auto-import 和 unplugin-vue-components 的自动引入组件原理后，我们不难发现两个插件帮我们引入的组件样式实际上是在 **组件内部生效的**，然而我们定义的变量文件却是在入口文件引入的，因此组件内部引入的哪些样式是取不到我们这里定义的全局变量的。

那么，怎么才能生效呢？我们不妨来想一下如果你定义了一个样式文件（variable.scss）来存储变量信息，你要怎么在其他样式文件中使用这个样式文件呢？没错，就是在其他文件内引入 `variable.scss`，就像这样：

```scss
@use "@/style/variables.scss" as *;

body {
	backgournd: $-bg-color
}
```

沿着这个思路，我们只要想办法将 `@use "@/stlye/element-variable.scss" as *;` 塞入每个 ElementPlus 组件的 scss 样式文件的第一行中就可以了。

`sass-loader` 正好提供了一个 `additionalData` 配置项，可以帮助们我们来将一些信息写入到每个 scss 文件中，因此我们需要在 webpack 的 scss loader 部分配置为：

```js
{
	test: /\.scss$/,
	use: [
		process.env.NODE_ENV === 'development' ? 'vue-style-loader' : MiniCssExtractPlugin.loader,
		'css-loader',
		'postcss-loader',
		{
			loader: 'sass-loader',
			options: {
			    additionalData: '@use "@/stlye/element-variable.scss" as *;',
			},
		},
		'css-unicode-loader',
	],
},
```

同时，因为 `ElementPlusResolver` 默认引入的是 ElementPlus 中的 css 文件，我们需要让其引入 scss 文件行，我们还需要将 plugin 做一下改造：

```diff
	plugins: [
		autoImport({
			resolvers: [
-				elementPlusResolver()
+				elementPlusResolver({
+					importStyle: 'sass',
+				}),
			],
		}),
		components({
			resolvers: [
-				elementPlusResolver(),
+				elementPlusResolver({
+					importStyle: false, // 两个 elementPlusResolver 都会自动引入样式文件，可以关闭一个
+				}),
			],
		}),
	]
```

之后我们定义的 ElementPlus 变量就可以完美使用了。