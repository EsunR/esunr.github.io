---
title: 使用 Rollup 构建 Vue2 & 3 的通用组件库
tags:
  - Rollup
  - Vue
  - 前端工程化
  - 组件库
categories:
  - 前端
  - 前端工程化
date: 2024-09-25 19:50:37
---
# 1. 背景

Vue3 在 Vue2 的基础之上做了很大的变更，因此**编译后的 Vue2 组件**并不能适用到 Vue3 项目中，这对团队将来升级 Vue 框架会是一种极大的限制，同时新项目也可能因为无法复用旧项目的资产而导致放弃使用全新的框架。

好在 Vue3 的 Composition API 移植到了 Vue2.7，并且低版本的 Vue 也可以通过安装 [@vue/composition-api](https://github.com/vuejs/composition-api/tree/2436ba2ca0ae804a3932924407f54e675073ea5c) 来得到支持。因此我们可以以此为桥梁，通过标准化的 Composition API 来编写 Vue2 与 Vue3 的通用组件。这一点很容易验证，在大多数情况下，我们编写的 setup 组件源码可以不经过修改就能同时在 Vue2、Vue3 项目中直接使用（但差异性仍然是存在的，具体可见 [Vue2.7 与 Vue3 的行为差异](https://v2.cn.vuejs.org/v2/guide/migration-vue-2-7.html#%E4%B8%8E-Vue-3-%E7%9A%84%E8%A1%8C%E4%B8%BA%E5%B7%AE%E5%BC%82)）。

有了思路之后，我们再来谈论下具体实现，通常编写 Vue 组件库有两种方案：

1. 将 SFC 组件源码（也就是 `.vue` 文件）发布到 NPM，使用方需要对其进行构建；
2. 将 SFC 组件源码编译为 JS 在进行发布到 NPM，业务方直接引入即可，无需对其进行编译；

这两种方式各有优劣：

- 直接发布源码的优势是成本低，可快速发布，但缺点是对使用方要求高，使用方需要完成 SFC 组件源码转为 JS 的这一过程，如果组件的提供方与使用方存在技术差异（如编写组件时使用了 TS，而组件的适用方项目中并不支持 TS），处理起来会比较麻烦。因此大多数开源组件库并不以这种方式来发布组件。
- 经过编译后发布源码的缺点是搭建组件库的成本较高，但除此之外就没有什么缺点了，组件的构建方可以使用 Babel、TS 等不会对使用方产生影响的技术栈，也可以将组件编译为更多的包规范提供给更多的项目使用，并且发不到 NPM 上的组件已经是被预编译过的源码，也降低了适用方编译的压力。

当然，两种实现方案具体用哪一个还是源于业务需求，他们也都有方法可以构建为 Vue2 与 Vue3 的通用组件，接下来我们将具体探讨一下具体的实施方案。

# 2. 使用 vue-demi 构建通用的 Vue 组件

如果想要通过源码方式来发布 Vue 组件到 NPM 上，那么使用 [vue-demi](https://github.com/vueuse/vue-demi) 是一个不错的选择。

## 2.1 原理

vue-demi 是一个专门用于抹平 Vue2 与 Vue3 组件开发差异性的库。vue-demi 并不负责通用的 vue composition api 的实现，而是通过重新导出的方式来自动将 composition api 指向正确的引入。

举例来说，当我们使用 vue-demi 编写了一个 Vue 组件并使用到了  Composition API：

```js
import {ref} form "vue-demi"
```

看似我们是从 vue-demi 这个包中引入的 ref 方法，但实际上 vue-demi 只是在包中从正确的 vue 版本中导出了 ref 方法，并从 vue-demi 再重新对其进行导出。比如：如果 vue-demi 检测到当前项目是 vue3 或者 vue2.7，那么 ref 方法就是从 vue 包中直接导出的具名函数；但是如果 vue-demi 检测到当前项目是 vue2.7 以下，那么其就会从 @vue/composition-api 这个包中（如果没有安装的话 vue-demi 会自动为该项目安装）导出对应的具名函数。

![image.png|500](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240926153505.png)

关于用户使用的 Vue 版本检测，vue-demi 会在 npm 装包的 postinstall 阶段执行[检测脚本](https://github.com/vueuse/vue-demi/blob/main/scripts/postinstall.js)，判断出正确的版本之后，脚本会动态复制所需的入口文件到 vue-demi 的包入口。

## 2.2 实践

vue-demi 开发组件库与普通的开发并无二致，只需要规范化的从 vue-demi 导出并使用 Composition API 即可。此外，当我们使用 vue-demi 开发完组件后，需要在 package.josn 中将 vue-demi 声明为组件库的依赖，这样才能保证适用方可以安装到 vue-demi：

```json
{
  "dependencies": {
    "vue-demi": "latest"
  },
  "peerDependencies": {
    "@vue/composition-api": "^1.0.0-rc.1",
    "vue": "^2.0.0 || >=3.0.0"
  },
  "peerDependenciesMeta": {
    "@vue/composition-api": {
      "optional": true
    }
  },
  "devDependencies": {
    "vue": "^3.0.0" // or "^2.6.0" base on your preferred working environment
  },
}
```

编写完成之后，就可以像其他直接发布 SFC 组件源码的组件库一样发布到 NPM 上了，开发的时候只需要注意 Vue2 Composition API 与 Vue3 的几处差异性即可，如果实在无法兼容，vue-demi 也提供了 Vue2 与 Vue3 的环境判断方法，编写对应的分支处理逻辑即可。

## 2.3 渲染函数上的差异性

Vue2 和 Vue3 在渲染函数的调用上有一定的区别（这也是 Vue3 与 Vue2 编译后组件不通用的原因之一），然而 vue-demi 并没有提供一个通用的渲染函数支持，如果我们需要使用 `render` 函数，就需要组件的开发人员手动处理这些差异，比如 [vue-echarts](https://github.com/ecomfe/vue-echarts) 的处理方式：

```ts
render() {
	// Vue 3 and Vue 2 have different vnode props format:
	// See https://v3-migration.vuejs.org/breaking-changes/render-function-api.html#vnode-props-format
	const attrs = (
	  Vue2
		? { attrs: this.nonEventAttrs, on: this.nativeListeners }
		: { ...this.nonEventAttrs, ...this.nativeListeners }
	) as any;
	attrs.ref = "root";
	attrs.class = attrs.class ? ["echarts"].concat(attrs.class) : "echarts";
	return h(TAG_NAME, attrs);
}
```

[源码参考](https://github.com/ecomfe/vue-echarts/blob/main/src/ECharts.ts)

此外，有人建议使用 h-demi 来解决差异性问题，具体可参考此 [issues](https://github.com/vueuse/vue-demi/issues/65)，在此不过多讨论。

# 3. 基于源码分别构建出适用于 vue2 & vue3 的组件库

前面我们讨论了如何快速的构建一个没有编译过程的 Vue 源码组件库，那么接下来我们讨论一种更好的解决方案：使用 Composition API 开发完 SFC 组件后，再额外编写一个编译器，编译器将调用不同的 Vue SFC 编译器产出两份编译后的组件库，分别适用于 Vue3、Vue2 项目，并分开发布到 npm。最终，使用方就可以根据需要分别安装不同版本的组件库即可：

![image.png|700](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240926172449.png)

完整的实践源码放在了这里：[EsunR/universal-vue-components](https://github.com/EsunR/universal-vue-components) ，后文将只讨论过程中的重点部分。

## 3.1 组件的编写

### 基准 Vue 版本的选择

我们既然要编写 vue2、vue3 的通用组件，那么必须得选择一个基准 Vue 进行开发，这里**推荐以 Vue2.7 为基准进行开发**。

这是因为 Vue2.7 已经完全使用 Typescript 重构，并且内置了 Composition API 的实现，不仅能使用 `defineProps`、`defineEmits` 这些组合式 API，并且组合式 API 对于 Typescript 的支持也与 Vue3.2 保持高度一致，比如可以使用 `defineEmits<{(e: 'some-event'): void}>()` 这种方式来声明组件事件；同时，如果以 Vue2.7 为基准而不是以更高版本的 Vue 进行开发，也能及时避免在开发组件时使用了过高版本的 API （如 Vue3.3 才支持的 `defineOptions`）导致编译失败。

### 组件编写参考示例

[组件目录结构参考](https://github.com/EsunR/universal-vue-components/tree/main/packages/src)：

```
.
├── README.md
├── components
│   ├── index.ts --------------- # 组件入口
│   ├── uni-comp
│   │   ├── index.ts ----------- # 组件入口
│   │   └── src
│   │       └── uni-comp.vue --- # 组件源码
│   └── other-comp
│       └── ... ...
├── global.d.ts ---------------- # ts 声明文件
├── index.ts ------------------- # 总入口
├── module.declare.d.ts -------- # ts 声明文件
├── package.json --------------- # 组件 package.json，最终对外发布
├── styles
│   └── src
│       └── uni-comp.styl ------ # 组件样式
├── tsconfig.json
└── utils
    └── ... ...
```

组件编写参考：

```html
// uni-comp.vue
<template>
    <div
        :class="classNs('uni-comp', `uni-comp--${type}`)"
        :title="`vue version: ${vueVersion}`"
    >
        <span class="count">{{ count }}</span>
        <button class="add-button" @click="addCount">Add</button>
    </div>
</template>

<script lang="ts" setup>
import {ref, toRefs, type PropType} from 'vue';
import {
	// 用于生成带命名空间的 class name
	classNs,
	// 判断当前是否是 Vue2 环境，具体实现后面讲
	IS_VUE2
} from '@src/utils';
import '@src/styles/src/uni-comp.styl';

// 推荐使用该方式定义 props，使用 defineProps<{/** ... */}>() 泛型方式编写会导致 vue2.7 项目无法识别 Props 提示
const props = defineProps({
    /** 默认值 */
    defaultValue: {
        type: Number as PropType<number>,
        default: 10,
        required: false,
    },
    /** 类型 */
    type: {
        type: String as PropType<'default' | 'large'>,
        default: 'default',
        required: false,
    },
});

const vueVersion = IS_VUE2 ? '2' : '3';

const {defaultValue} = toRefs(props);

const count = ref(defaultValue.value);

function addCount() {
    count.value += 1;
}
</script>
```

组件入口参考：

```ts
// index.ts
import {withInstall} from '../../utils';
import Component from './src/uni-comp.vue';

export const UniComp = withInstall(Component);
export default UniComp;
```

```ts
// utils.ts
export type SFCWithInstall<T> = T & {
    install: (app: any) => void;
};

/**
 * 为组件扩展 install 方法，使是组件可以通过 app.use(component) 的方式使用
 */
export const withInstall = <T>(comp: T) => {
    (comp as SFCWithInstall<T>).install = function (app) {
        app.component((comp as any).name, comp as any);
    };
    return comp as SFCWithInstall<T>;
};
```

总入口文件参考：

```ts
// 组件导出
export * from './components';
```

## 3.2 编译器的编写

对于组件的编译，推荐使用 [Rollup](https://rollupjs.org/) 进行构建，但这里不会详细讨论 Rollup 构建 Vue 组件库的方式。

基本的流程如下：

1. 确定当前的 Vue 构建目标，然后启用 rollup 的构建流程；
2. 根据构建目标分别调用 Vue2 与 Vue3 的 SFC 组件编译器；
3. 如果存在 Typescript 组件，则使用 esbuild 对 Typescript 进行编译；
4. 如有需要，在过程中引入 babel 对语法进行降级处理以及引入语法垫片；
5. 让 rollup 输出 cjs、esm、umd 规范的包；
6. 生成组件的类型声明文件；

### 编译 SFC 组件

由于我们直接使用 SFC 编写组件，因此需要先去处理这些 `.vue` 文件，对于不同版本的 Vue 编译过程最大的区别就在这里，我们将对其详细讨论，并简述 rollup 的配置过程。

首先我们要安装 Vue 官方针对 vite 编写的 Vue2 和 Vue3 的 SFC 组件编译器：[@vitejs/plugin-vue](https://www.npmjs.com/package/@vitejs/plugin-vue) 和 [@vitejs/plugin-vue2](https://www.npmjs.com/package/@vitejs/plugin-vue2)（这两个 vite 插件是兼容 rollup 调用的），并在 rollup 中对其进行配置：

```sh
pnpm install vite @vitejs/plugin-vue @vitejs/plugin-vue2
```

> pnpm 安装会提示 missing peer，后面解释原因。

> 我们的项目整体使用 pnpm 管理，并且利用到了其 shamefully-hoist 的特性，这一点很重要。

```ts
import vue3 from '@vitejs/plugin-vue';
import vue2 from '@vitejs/plugin-vue2';

// 判断当前的构建目标是否是 vue2
const IS_VUE2 = process.env.VUE_VERSION === '2';

const rollupOption: RollupOptions = {
	// ... ...
	plugins: [
		IS_VUE2 ? vue2() : vue3(),
		// ... ... eslint, babel plugin etc.
	]
}
```

但是，当我们尝试去构建 vue2 的时候就会出现类似的报错：

```
[15:21:22] TypeError: source.startsWith is not a function
    at startsWith (/Users/carb/Documents/Code/github/uni-vue-components/node_modules/.pnpm/@vue+compiler-core@3.2.47/node_modules/@vue/compiler-core/dist/compiler-core.cjs.js:1592:19)
```

这是因为无论是 @vitejs/plugin-vue 和 @vitejs/plugin-vue2，他们都不负责具体的 SFC 组件编译的实现，在他们内部调用的实际是 [@vue/compiler-sfc](https://www.npmjs.com/package/@vue/compiler-sfc)，这个包是专门负责 SFC 组件的编译，跟随每个 Vue 版本进行发布，属于 vue 的一个子包（3.2.13+ & 2.7）。

话说回来，当我们同时安装了 @vitejs/plugin-vue 和 @vitejs/plugin-vue2，他们都会去查找 @vue/compiler-sfc，然而 vue2 需要找 2.7 版本的 @vue/compiler-sfc，而 vue3 需要找 3.2 版本的 @vue/compiler-sfc，但实际上 node_modules 中只能索引到一个 vue 与一个 @vue/compiler-sfc 版本（前面出现了 miss peer 的原因），因此必定会导致 @vitejs/plugin-vue、@vitejs/plugin-vue2 其中一个包调用的 @vue/compiler-sfc 版本是错误的。**那么我们要解决的就是为这两个插件指定正确的 @vue/compiler-sfc**。

首先我们要想办法将 vue2 和 vue3 需要的 @vue/compiler-sfc 都安装到项目的 node_modules 里，我们都知道一个项目是无法安装两个同名包的，但是我们可以使用别名的方式进行安装：

```sh
# 将 vue2.7 安装到 node_modules/vue2 目录下
pnpm install vue2@npm:vue@2.7

# 将 vue3.2 安装到 node_modules/vue2 目录下
pnpm install vue3@npm:vue@3.2
```

由于 pnpm shamefully-hoist 与隔离的这一特点，pnpm 会将 vue2、vue3 依赖的 @vue/compiler-sfc 放到其各自的 node_modules 下，从而保证依赖的正确性：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240927155717.png)

因此，因此我们便可以使用 `vue2/compiler-sfc`、`vue3/compiler-sfc` 来分别导出 vue2 和 vue3 的 SFC 编译器，然后再将其指定给对应的插件即可：

```ts
import vue3 from '@vitejs/plugin-vue';
import vue2 from '@vitejs/plugin-vue2';
// 导入 Vue2 的 SFC 组件编译器
import * as vue2Compiler from 'vue2/compiler-sfc';
// 导入 Vue3 的 SFC 组件编译器
import * as vue3Compiler from 'vue3/compiler-sfc';

// 判断当前的构建目标是否是 vue2
const IS_VUE2 = process.env.VUE_VERSION === '2';

const rollupOption: RollupOptions = {
	// ... ...
	plugins: [
		(IS_VUE2
            ? vue2({
	            // 指定编译器
                compiler: vue2Compiler as any,
            })
            : vue3({
	            // 指定编译器
                compiler: vue3Compiler as any,
            })) as any,
        // ... ... eslint, babel plugin etc.
	]
}
```

最终，同一份 SFC 组件源码编译出的 Vue2 组件和 Vue3 组件对比如下：

编译后的 Vue2 组件：

```js
import _sfc_main from './uni-comp.vue2.mjs';
import normalizeComponent from '../../../_virtual/_plugin-vue2_normalizer.mjs';

var _sfc_render = function render() {
  var _vm = this, _c = _vm._self._c, _setup = _vm._self._setupProxy;
  return _c("div", { class: _setup.classNs("uni-comp", `uni-comp--${_vm.type}`), attrs: { "title": `vue version: ${_setup.vueVersion}` } }, [_c("span", { staticClass: "count" }, [_vm._v(_vm._s(_setup.count))]), _c("button", { staticClass: "add-button", on: { "click": _setup.addCount } }, [_vm._v("Add")])]);
};
var _sfc_staticRenderFns = [];
_sfc_render._withStripped = true;
var __component__ = /* @__PURE__ */ normalizeComponent(
  _sfc_main,
  _sfc_render,
  _sfc_staticRenderFns);
__component__.options.__file = "/Users/carb/Documents/Code/github/uni-vue-components/packages/src/components/uni-comp/src/uni-comp.vue";
var Component = __component__.exports;

export { Component as default };
//# sourceMappingURL=uni-comp.vue.mjs.map
```

编译后的 Vue3 组件：

```js
import _sfc_main from './uni-comp.vue2.mjs';
import { openBlock, createElementBlock, normalizeClass, createElementVNode, toDisplayString } from 'vue';
import _export_sfc from '../../../_virtual/_plugin-vue_export-helper.mjs';

const _hoisted_1 = ["title"];
const _hoisted_2 = { class: "count" };
function _sfc_render(_ctx, _cache, $props, $setup, $data, $options) {
  return openBlock(), createElementBlock("div", {
    class: normalizeClass($setup.classNs("uni-comp", `uni-comp--${$props.type}`)),
    title: `vue version: ${$setup.vueVersion}`
  }, [
    createElementVNode(
      "span",
      _hoisted_2,
      toDisplayString($setup.count),
      1
      /* TEXT */
    ),
    createElementVNode("button", {
      class: "add-button",
      onClick: $setup.addCount
    }, "Add")
  ], 10, _hoisted_1);
}
var Component = /* @__PURE__ */ _export_sfc(_sfc_main, [["render", _sfc_render], ["__file", "/Users/carb/Documents/Code/github/uni-vue-components/packages/src/components/uni-comp/src/uni-comp.vue"]]);

export { Component as default };
//# sourceMappingURL=uni-comp.vue.mjs.map
```

可以看出，Vue3 在 Vue2 基础上增加了很多渲染函数，逻辑处理上也有很大的差异，因此编译后的组件是没办法同时在 Vue3 和 Vue2 上运行的，只能单独发包。

> [构建器实现参考](https://github.com/EsunR/universal-vue-components/blob/main/packages/builder/builders/modules.ts)

### 组件如何判断当前环境是 Vue2 还是 Vue3

在 Node 环境中，只要我们指定了环境变量，就可以通过 `process.env.VUE_VERSION` 来判断当前执行的 Vue2 还是 Vue3 的构建。但是在组件中，其最终的运行环境是浏览器，并且没有 VUE_VERSION 这个环境变量来判断。因此在构建时，我们就需要将 VUE_VERSION 这个环境变量值注入到组件库中。

在此我们可以使用 [@rollup/plugin-replace](https://www.npmjs.com/package/@rollup/plugin-replace) 插件，其可以将 `process.env.IS_VUE2` 硬编码为具体的环境变量值：

```ts
const rollupOption: RollupOptions = {
	// ... ...
	plugins: [
		replace({
            'process.env.VUE_VERSION': process.env.VUE_VERSION,
        }),
        // ... ..
	]
}
```

组件编译前：

```html
<template>
	is vue2: {{IS_VUE2}}
</template>

<script setup>
const IS_VUE2 = process.env.VUE_VERSION === '2';
</script>
```

组件编译后（假设构建目标是 Vue2）：

```html
<template>
	is vue2: {{IS_VUE2}}
</template>

<script setup>
const IS_VUE2 = '2' === '2';
</script>
```

这里再特别提一句，有的同学可能考虑使用 [rollup-plugin-inject-process-env](https://www.npmjs.com/package/rollup-plugin-inject-process-env) 这个插件来注入 `process.env`。该插件并不会将 `process.env` 进行硬编码，而是将其转成一个 helper 函数：

```ts
(function() {
    const env = {"VUE_VERSION":"3"};
    try {
        if (process) {
            process.env = Object.assign({}, process.env);
            Object.assign(process.env, env);
            return;
        }
    } catch (e) {} // avoid ReferenceError: process is not defined
    globalThis.process = { env:env };
})();
```

这样组件代码在运行时就可以获取到 env 变量。但是这种方法与 webpack 的 EnvironmentPlugin 插件会有冲突，EnvironmentPlugin 也会尝试处理上面这个 helper 函数的 process.env，最终导致上面的 helper 函数被改写错误，因此不推荐使用该插件。

### 为组件编译出 dts 声明文件

既然我们组件可以用 Typescript 编写 Vue 组件，那么对应的我们就应该为这些 TS 组件生成 dts 声明文件方便其他用户的使用，这样组件在调用时就回出现 props 提示以及类型校验，效果如下：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240927171714.png)

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240927171800.png)

但是，Vue 官方并没有提供由 SFC 组件生成对应类型声明文件的工具，好在我们有 [ts-morph](https://ts-morph.com/) 这把瑞士军刀，具体的实现方案为：

1. 使用 complier-sfc 解析出 SFC 组件的 script 部分；
2. 使用 ts-morph 来分析 script 部分的 ts 代码，并解析出类型声明；
3. 将类型声明内容写入到 dist 目录中对应的组件 js 旁，生成 dts 文件；

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240927171225.png)

[编译 dts 声明文件的完整实现参考](https://github.com/EsunR/universal-vue-components/blob/main/packages/builder/builders/types-definitions.ts)

但是需要注意的是，由于我们使用了 pnpm，其 shamefully-hoist 特性并不会将间接依赖的包放在 node_modules 根目录下，并且包是通过软链的方式进行访问的，因此 ts-morph 自己的模块索引方法并不能很好的处理这些问题，可能会导致某些包无法查找到，举例来说：

项目中依赖某个包 module@1.0.0，这个包又依赖 peer@1.0.0。对于 npm 项目来说，npm 会直接将 module 和 peer 都安装到 node_modules 目录下（没有依赖冲突的情况下），这样 ts-morph 在解析 module 对 peer 的引入时，能查找到 peer 模块。

然而对于 pnpm 来说，依赖包是严格被隔离的，**没有指定安装的包是不会出现在项目 node_modules 根目录下的** 。module 的真实安装路径为 `node_modules/.pmpm/module@1.0.0/node_modules/module`，peer 的真实安装路径位于 module 的同级目录下，也就是 `node_modules/.pmpm/module@1.0.0/node_modules/peer`。但是由于 module 是当前项目指定安装的依赖，会通过软链连接到 `node_modules/module` 目录下，然而 peer 并属于子依赖，并非当前项目的直接依赖，根据 shamefully-hoist 原则，peer 不会显示在 node_modules 的根目录下。

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20240929110546.png)

NodeJS 对于软链会做真实路径的解析，因此 pnpm 这种嵌套隔离 + 软链接的方式是可以正常进行模块查找的。但是 ts-morph 并不会解析软链，它不会从 module 安装的真实路径（`node_modules/.pmpm/module@1.0.0/node_modules/module`）来开始查找 peer，而是依然从软链的路径（`node_modules/module`）开始进行 peer 包查找，那自然无法正常找到了。因此，我们必须告诉 ts-morph，如果是软链的话，将软链解析为真实路径在进行模块查找，才能正确找到目标包。

我们可以编写一个 ts-morph 的自定义模块解析器来实现这一行为：

```ts
/**
 * ts-morph 自定义模块解析器
 */
function customModuleResolution(
    moduleResolutionHost: ts.ModuleResolutionHost,
    getCompilerOptions: () => ts.CompilerOptions
): ResolutionHost {
    return {
        resolveModuleNames(
	        // 当前文件引入的模块列表
	        moduleNames,
	        // 当前索引到的文件
			containingFile
		) {
            let containingFileRealPath = containingFile;
            // 由于项目使用了 pnpm，npm 包实际是以软链的方式链接在 node_modules 下的，因此在 resolve 前需要转为真实路径
            try {
                containingFileRealPath = fs.realpathSync(
                    containingFile,
                    'utf-8'
                );
            } catch {
                // 找不到没关系，因为找不到的文件是在 Project 中存储的虚拟文件
            }
            moduleNames = moduleNames
                .map(removeTsExtension)
                .map(mapModuleAlias);
            const compilerOptions = getCompilerOptions();
            const resolvedModules: ts.ResolvedModule[] = [];
            for (const moduleName of moduleNames.map(removeTsExtension)) {
	            // 调用模块解析方法，传入真实的文件路径来查找包
                const result = ts.resolveModuleName(
                    moduleName,
                    containingFileRealPath,
                    compilerOptions,
                    moduleResolutionHost
                );
                if (result.resolvedModule) {
                    resolvedModules.push(result.resolvedModule);
                } else {
                    // 无法解析的模块不影响 dts 的生成，所以只是警告（如果是非 assets 模块则不需要理会，其他模块最好排查一下错误原因）
                    if (!/\.(css|styl|style)/.test(moduleName)) {
                        consola.warn(
                            `[types definition] Cannot resolve module: ${moduleName}`
                        );
                    }
                    resolvedModules.push(undefined as any);
                }
            }

            return resolvedModules;
        },
    };
}

/**
 * 移除 ts 文件后缀
 * import module form 'module.ts' -> import module form 'module'
 */
function removeTsExtension(moduleName: string) {
    if (moduleName.slice(-3).toLowerCase() === '.ts') {
        return moduleName.slice(0, -3);
    }
    return moduleName;
}

/**
 * 将模块名映射为对应的包名
 * !!! 注意：这里修改 moduleName 是为了让 ts-morph 正确解析依赖，并不会修改最终输出代码的模块名称
 * !!! 输出代码的模块名称仍然会按照原有名称输出，如果需要修改输出的模块名，在下面的 outputContentReplacer 中修改
 */
function mapModuleAlias(moduleName: string) {
    // 根据构建目标修正 Vue 索引的版本
    // e.g. 构建 Vue3 组件库时 import {createApp} form 'vue' -> import {createApp} form 'vue3'
    if (['vue', 'vue2', 'vue3'].includes(moduleName)) {
        moduleName = IS_VUE2 ? 'vue2' : 'vue3';
    }
    // 正确索引到 @src
    // import module form '@src/components' -> import module form 'project-path/packages/src/components'
    moduleName = moduleName.replace('@src', compsSrcPath);
    return moduleName;
}
```

此外，在组件编译类型时，可能发生报错 TS2742，具体报错信息为类似：

```
 ERROR  ../src/components/uni-comp/src/uni-comp.vue.ts:7:1 - error TS2742: The inferred type of 'default' cannot be named without a reference to '.pnpm/vue@2.7.16/node_modules/vue/types/common'. This is likely not portable. A type annotation is necessary.
```

这类问题的缘由都一样，以上面的报错信息为例，出现报错的原因是因为组件内使用了 `defineProps({...})` 来声明组件 Props 引发的。经由编译后的 TS 类型声明文件中会使用到 `LooseRequired` 接口，然而该接口并未在 `vue` 中作为默认使用导出，所以编译器需要按照相对路径对其进行引用，由于我们使用了 pnpm，所以该接口在当前设备下引用的地址为 `.pnpm/vue@2.7.16/node_modules/vue/types/common`。但是我们编译出的类型声明文件是需要给别人用的，在他人的设备下引用路径不一定是这个，所以 ts 编译器会检测到该路径在其他设备上不适用，对其进行报错。

解决方案：在入口文件中声明一下导出位置，这样 ts 就能知道如何去引用类型了：

```ts
// packages/vr-components/src/index.ts
import type {} from 'vue2/types/common';
import type {} from '@vue/shared';
```

[参考](https://github.com/microsoft/TypeScript/pull/58176#issuecomment-2052698294)

## 3.3 在不同的 Vue 版本下调试组件

我们可以通过搭建一个 Vite 服务来调试组件在不同版本 vue 环境下的表现，因此 Vite 也必须同时支持 Vue2 和 Vue3 的两种编译模式。为了达到这一目的，我们可以创建一个 Playground 模块，与我们编写组件编译器类似的，我们需要在 Playground 模块中同时安装 Vue2 和 Vue3：

```sh
# 将 vue2.7 安装到 node_modules/vue2 目录下
pnpm install vue2@npm:vue@2.7

# 将 vue3.2 安装到 node_modules/vue2 目录下
pnpm install vue3@npm:vue@3.2
```

然后我们通过 Vite 服务启动时的环境变量来决定 Vite 使用 Vue2 的构建还是 Vue3 的构建，`vite.config.ts` 的参考如下：

```ts
import {defineConfig} from 'vite';
import vue2 from '@vitejs/plugin-vue2';
import vue3 from '@vitejs/plugin-vue';
import * as vue2Compiler from 'vue2/compiler-sfc';
import * as vue3Compiler from 'vue3/compiler-sfc';
import path from 'path';

// 根据环境变量判断启动的 Vue 版本
const IS_VUE2 = process.env.VITE_VUE_VERSION === '2';

export default defineConfig({
    plugins: [
	    // 与 Rollup 中我们的配置一样
        IS_VUE2
            ? vue2({
                  compiler: vue2Compiler as any,
              })
            : vue3({
                  compiler: vue3Compiler,
              }),
    ],
    resolve: {
        alias: {
	        // 定向到正确的 Vue 版本
            vue: IS_VUE2 ? 'vue2' : 'vue3',
            '@': path.resolve(__dirname, './src/'),
            // 映射组件源码中使用的 @src 路径别名
            '@src': path.resolve(__dirname, '../src/'),
        },
    },
});
```

此外，不同版本的 Vue 入口是不一样的，比如 Vue2 中我们需要使用 `new` 创建一个 Vue 实例，而在 Vue3 中我们则是使用 `createApp` 创建一个 app 实例，因此入口需要分开定义：

```ts
// main_vue2.ts, vue2 入口
import Vue from 'vue2';
import './style.css';
import App from './App.vue';

new Vue({
    render: h => h(App as any),
}).$mount('#app-content');
```

```ts
// main_vue3.ts, vue3 入口
import {createApp} from 'vue3';
import './style.css';
import App from './App.vue';

const app = createApp(App);
app.mount('#app');
```

HTML 模板也要变更，我们使用一个模板字符来代替入口文件：

```diff
<!doctype html>
<html lang="zh-CN">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Uni Component</title>
  </head>
  <body>
    <div id="app">
        <div id="app-content"></div>
    </div>
+     <script type="module" src="/src/main_vue%VUE_VERSION%.ts"></script>
  </body>
</html>
```

配合 Vite 的插件功能，我们在编译 HTML 时，将模板字符 `VUE_VERSION` 进行替换：

```diff
// vite.config.ts
// ... ...
export default defineConfig({
    plugins: [
        // ... ..
+       {
+           name: 'html-rewriter',
+           transformIndexHtml(html: string) {
+               return html.replace(/%VUE_VERSION%/g, IS_VUE2 ? '2' : '3');
+           },
+       },
    ],
    // ... ...
});
```

我们在 package.json 中定义不同的启动脚本：

```json
{
    "scripts": {
        "dev:vue2": "cross-env VITE_VUE_VERSION=2 vite",
        "dev:vue3": "cross-env VITE_VUE_VERSION=3 vite"
    }
}
```

[Playground 模块实现参考](https://github.com/EsunR/universal-vue-components/tree/main/packages/playground)