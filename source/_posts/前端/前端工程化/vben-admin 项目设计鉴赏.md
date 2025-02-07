---
title: veben-admin 项目设计鉴赏
tags:
  - Vue
  - 前端工程化
categories:
  - 前端
  - 前端工程化
date: 2025-01-09 20:23:45
---
# 第三方包

- radix-vue：Radix UI 的 Vue 实现
- shadcn-ui：其并非是一个组件库（不通过 npm 发布），而是一组可重用的组件实践，用户需要将组件源码直接复制到项目中使用；
- defu：轻量级的对象属性合并函数（mesrge）

# 使用 catalog 统一 monorepo 项目的包依赖版本号

[官方文档](https://pnpm.io/catalogs)

在 monorepo 项目中，各个子模块中依赖的“基础” npm pacakge 他们的版本号应该是一致的，比如：

- 在 Vue 项目中，各个模块的 Vue 版本应该保持一致；
- eslint、prettier、typescript 这种开发依赖都应该保持一致，方便维护；

但你也可以用一些方案来规避这一问题：

- 将这些“公共包”都使用 `pnpm install xxx -w` 安装在工作区目录，从而保证全局的模块都是从根目录寻包，但是对于 monorepo 的设计思想来说，每个子包的依赖都应该是独立的，所以这一做法实际上并不稳妥，它会逐渐导致你子包的依赖变得不清晰，也会让子包的依赖散落的导出都是；
- 使用 `pnpm dedupe` 来将已安装的包统一到当前可用的最高版本；

pnpm catalog 就是用来处理这一问题的，我们可以在 `pnpm-workspace.yaml` 中声明 catalog 配置来定义项目中公共包的版本号，比如：

```yaml
catalog:
	vue: ^3.5.13
	'@vue/reactivity': ^3.5.13
	'@vue/shared': ^3.5.13
	'@vue/test-utils': ^2.4.6
	'@vueuse/core': ^12.2.0
```

此时，如果你在子包使用 `pnpm add vue`，那么在子包的 `package.json` 中，这些在 catlog 中定义过的包就会变为：

```json
"dependencies": {
	"vue": "catalog:",
	... ...
}
```

# 使用 unbuild 构建子包

unbuild 是一个基于 rollup 的、开箱即用的构建工具，其内部集成了多中 rollup 插件并自动启用，因此用于快速构建一个基于 Typescript 的 JavaScript lib 是一个非常好的选择。vben 将其用于 lib 的构建工具之外，最主要的是利用了其可以编译 JIT（运行时编译）包来简化重新构建依赖的负担。

unbuild 引入了 jiti 用于将 ts 源码文件进行实时编译，当我们执行 `unbuild --stub` 后，unbuild 并不会直接生成一个 js bundle，而是生成一个入口文件，如下：

```js
import { createJiti } from "../../../../node_modules/.pnpm/jiti@2.4.2/node_modules/jiti/lib/jiti.mjs";

const jiti = createJiti(import.meta.url, {
  "interopDefault": true,
  "alias": {
    "@vben/eslint-config": "/Users/jiguangrui/Documents/code/demo/vue-vben-admin/internal/lint-configs/eslint-config"
  },
  "transformOptions": {
    "babel": {
      "plugins": []
    }
  }
})

/** @type {import("/Users/jiguangrui/Documents/code/demo/vue-vben-admin/internal/lint-configs/eslint-config/src/index.js")} */
const _module = await jiti.import("/Users/jiguangrui/Documents/code/demo/vue-vben-admin/internal/lint-configs/eslint-config/src/index.ts");

export const defineConfig = _module.defineConfig;
```

入口文件利用 `jiti.import` 将源码文件进行了引用，这样当其他的代码引用了 unbuild 构建的代码后其实是调用 jiti 的运行时函数，实时的将源码编译为 js。

vben 将 `internal` 目录下使用 TS 编写的包都使用 unbuild 生成了 JIT 包，这样既保证了 node 能够正常运行这些经过 jiti 包装过的 TS 代码（比如提供给项目中的 lint 工具、tailwind、vite 使用），又不需要实时的对代码进行重新编译，减轻了开发负担。

# BEM 类名规范实践

在 vben 中，编写 CSS 用了三种方案：CSS Module、Tailwind CSS、BEM，其中 BEM 可以看做是解决那些不得不写在全局的样式命名冲突的问题。

对于书写 template 中的 DOM Class，vben 在 `@vben-core/composables` 提供了一个 `useNamespace` 的 hook，可以解构出 `b` `e` `m` `be` `em` ... 几个生成类名的方法。

对于书写 SCSS 时，在 `@vben-core/design` 中提供了 `b` `e` `m` 三个 minxin 来辅助书写 BEM 类名，该 mixin 被 `global.scss` 引用，最终会经过 vite 的 scss plugin 进行全局注入，因此可以全局使用。此外，由于 scss 的类名可嵌套、可继承的特性，其并不需要穷举出来所有的 b、e、m 函数组合，只需要按照结构嵌套使用即可。

最后补充，BEM 在 vben 中并非强制使用的类名规范，其只也在 `menu-ui` 模块中被使用。BEM 本身也只适合在构建规范化的基础组件库时使用，在业务中如果一昧追求 BEM 的类名规范化是在为项目徒增成本。

# Turborepo

[官方文档](https://turbo.build/repo/docs)

vbe 使用 turborepo 来管理子包的构建、开发、单元测试等指令。

在使用 turborepo 前，启动 monorepo 项目子包的开发指令通常需要进入到对应的 workspace 目录，或者使用 `--filter`、亦或在 `package.json` 中配置 script，这就导致运行子包的指令变得繁杂且难以维护。更在灾难的是如果需要对所有 workspace 执行构建、lint 指令的时候，启动将变得麻烦，并且运行速度也很慢。

turborepo 通过 `turbo.json` 配置，来配置 turbo 任务，从而让我们更好的启动项目指令，同时其也在内部对任务执行进行了优化、缓存，相对于单纯并发的调用 workspace 中的指令，turborepo 的执行速度会更快。

使用前：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20250111204101.png)

使用后：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20250111204121.png)

vben 除了使用 `turbo run` 指令外，自己还封装了一个 `turbo-run` 指令（`scripts/turbo-run`），这是因为 turborepo 只能并发启动任务。但是对于 `dev` 这种任务，通常只需要启动单独一个服务，但是 turborepo 并不支持独立启动一个 workspace 任务，因此 vben 使用 clack 自己实现了一个允许用户自行选择的启动脚本（脚本本身并没有调用 turboreoo）。

# 状态管理

vben 将 store 层通用的部分单独抽离到了 `@vben/stores` 这个子包中，多应用都从此处引用通用的 store。

通用的 store 有如下几个：

- core-user：
	- 存放用户信息、角色等内容；
	- 对外提供的 action：
		- setUserInfo：传入接口返回的用户信息，对 userInfo 进行 set，并解构出 rules 进行 set；
		- setUserRules：传入 rules 进行 set；
- core-access：
	- 存放权限码、可访问的菜单列表、可访问路由列表、token、登录状态；
	- 对外提供的 action 为：
		- getMenuByPath：根据 path 获取对应的菜单配置；
		- setState 系列函数；
- core-lock：提供给 layout 的锁屏组件使用的 state（感觉不是很有必要放在 state，作为组件 inject 就可以）
	- 存放锁屏相关的 state
	- 对外提供的 action 为：
		- lockScreen：传入密码，写入 state
		- unlockScreen：解锁屏幕，重置 state
- core-tabbar：处理顶部 tab 相关逻辑

此外还提供了几个工具函数，可以供应用直接引入：

- initStores：获取一个 pina 实例，为该 pina 实例装载一个持久化的插件（pinia-plugin-persistedstate）
- resetAllStoers：获取 pina 中所有的 state，并调用他们的 [$reset](https://pinia.vuejs.org/zh/api/interfaces/pinia._StoreWithState.html#reset) 方法

# 接口请求

在 `packages/effects/request` 目录下，vben 基于 axios 构造了一个 `RequestClient` 类，相较于原始的 axios 其做了如下行为：

- 构造函数传入的配置项为 `axios.create()` 传入的配置项，但是 `RequestClient` 为其添加了一些额外的默认参数，比如 headers、timeout；
- 构造出的实例继承 `axios.create()` 创建的 axios 实例的原型链；
- 通过 `addResponseInterceptor`、`addResponseInterceptor` 来管理拦截器；
- 重新封装了一层 get、post、delete、put、request 基础方法，但是并没有做额外的事情；
- 新增了 `upload` 方法，用于方便传递 `multipart/form-data` 数据；
- 新增了 `download` 方法，用于下载 blob；

此外，request 目录下还封装了 `authenticateResponseInterceptor` 用来做 Token 刷新和重新认证。调用方需要将请求函数、重认证函数（指用户过期后采取的行为，比如跳转到登录页面并清空缓存）、token 刷新函数等传递给该方法，该方法返回一个拦截器提供给 `addResponseInterceptor` 调用。其内部实现为：

- 检查请求拦截原因是否是 401；
- 如果是已经重新发起过的请求、或者禁用了自动刷新 token 功能，则执行重认证函数（跳转到登录页）；
- 如果正在刷新 token，则将发送中的请求放入队列等待刷新完成后重试；
- 调用刷新 token 函数；
- 请求成功后，重新发送等待队列中的请求；

# 用户鉴权

每个 app 的用户鉴权都是独立的，在 **app** 的 store 目录下，`auth.ts` 模块负责了用户鉴权相关的内容。

在该模块下，对外暴露了 `authLogin` 函数，提供给点击用户登录按钮时调用，做了如下事务：

1. 调用登录接口，传入用户名账号密码；
2. 将接口返回的 `accessToken` 存入 `accessStore`;
3. 调用 `fetchUserInfo` 函数，获取用户信息；
	1. `fetchUserInfo` 中调用获取用户信息的接口，并将用户信息存放在 `userStore` 中；
4. 调用 `getAccessCodesApi` 接口，获取用户权限信息；
5. 登录成功，跳转到 home 页面；
6. 弹出欢迎 notification；
7. 返回 `{ userInfo }`

此外该模块还提供了 `logout` 方法，在 token 过期、用户主动登出时进行调用，主要做了如下事务：

1. 调用登出接口通知后端；
2. 重置所有的 store；
3. 将 `accessStore` 中标记用户登录过期的字段标记为 `false`；
4. 路由定向到登录页（同时为路由添加 redirect 字段）

> token 过期、重认证的逻辑都在“接口请求”章节

# 页面路由

- router
	- index.ts：
		- 路由入口文件，调用 createRouter 生成路由对象
		- 调用 `resetStaticRoutes` 删除没有 `name` 属性的路由
		- 创建路由守卫
	- access.ts：
		- 对外导出 `generateAccess` 方法，用于生成经过权限过滤的路由 Raw 和菜单
		- 生成路由有两种方式：
			- 前端模式：通过 route.meta.authority 来过滤出有权限的路由
			- 后端模式：后端接口生成 RouteRecordRaw 后前端进行匹配和应用
	- guard.ts：
		- 设置页面加载进度条效果
		- 检查是否生成过动态路由，否则调用 access 模块来生成有权限的路由（addRoute 行为发生在 `generateAccessible` 中）
		- 在上一步生成有权限的路由后还会生成菜单配置，将其都存到 store 层
		- 检查 query 是否有 redirect 字段，有则进行重定向
	- routes
		- index.ts
			- 扫描 modules 目录获取所有的 Module
			- 调用 `mergeRouteModules` 将所有的 Module 合并为一个 `RouteRecordRaw[]`
			- 将核心路由、动态路由、静态路由合并
			- 模块对外导出合并后的路由对象
				- accessRoutes：有权限校验的路由列表，包含动态路由和静态路由
				- coreRouteNames：核心路由名称列表，这些路由不需要进入权限拦截
				- routes：路由列表，由基本路由、外部路由和404兜底路由组成
		- core.ts：定义登录路由、404 路由等核心页面的路由
		- modules：动态路由


# 接口 mock

vben 内置了一个 mock 服务器，供前端人员 Mock 服务接口使用，位于 `apps/backend-mock`。

当环境变量 `VITE_NITRO_MOCK` 被设置为 `true` 且非构建模式时，vite 会加载 `viteNitroMockPlugin` 插件，该插件通过调用 [Nitro](https://nitro.build/) 相关的 API 来启动一个 Nitro 服务来进行接口 mock。

开发人员只需要按照 nitro 的规范在 `/api` 目录下创建对应的文件即可创建接口路由，详情查看 [Nitro 相关的文档](https://nitro.build/guide/routing)。

# i18n

# Layout

# lint 工具管理

# 偏好设置

偏好（preference）的设置散在 vben 项目多个位置，因为偏好设置与 app 耦合，但本身又属于 vben 核心实现的一环，其相关实现存在在以下几个目录：

- `packages/preferences`：
	- 提供了 `defineOverridesPreferences` 函数，本身只是一个返回配置项的函数，通过 ts 配置为了方便生成配置信息而创建的函数，类似 Vue 的 `defineOptions`；
	- 对 `@vben-core/preferences` 进行了重导出；
- `packages/@core/preferences`：
	- 实现 PreferenceManager 类，并通过单例模式对外暴露一个 preferencesManager 实例供外部调用，所有的偏好相关设置都通过该实例进行管理；
	- 在入口对外暴露清理偏好设置缓存、初始化偏好设置、更新偏好设置等工具函数；
- `app/<app-name>/preferences.ts`：
	- 调用 `defineOverridesPreferences` 函数，配置当前应用的默认偏好设置，并返回一个配置列表；
	- 在应用入口 `main.ts` 中调用 `initPreferences` 函数，将上一步返回的配置列表传入该初始化函数，以覆盖 `@vben-core/perferences` 默认提供的配置；

最终，在应用需要的位置通过调用 `import { preferences } from '@vben/preferences'` 来进行用户偏好配置的读写。

# 图标

# 主题切换

TODO: view-transition 动画分析