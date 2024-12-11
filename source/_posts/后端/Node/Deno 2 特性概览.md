基于视频：[Announcing Deno 2](https://www.youtube.com/watch?v=d35SlRgVxT8&t=626s)

# Typescript support

Deno 无需配置即支持 Typescript。

许多 npm 包附带类型，您可以导入它们并直接将它们与类型一起使用：

```ts
import chalk from "npm:chalk@5";
```

有些软件包不附带类型，但您可以使用 @eno-types 指令指定它们的类型。例如，使用 @types 包：

```ts
// @deno-types="npm:@types/express@^4.17"
import express from "npm:express@^4.17";
```

Node 附带了许多内置类型，例如 Buffer，它们可能会在 npm 包的类型中引用。要加载这些，您必须将类型引用指令添加到 @types/node 包：

```ts
/// <reference types="npm:@types/node" />
```

# Package manager

deno 拥有 npm 一样的包管理指令：

- deno install
- deno add
- deno remove

当项目存在 pacakge.josn 时，deno 会在项目中创建 node_modules 来进行依赖缓存。如果没有 package.json，deno 会读取 deno.json 并从全局缓存中进行查找或安装。

## 可执行的 npm 脚本

类似 `npx`、`pnpm exec` 指令，deno 也可以直接运行 npm 脚本：

```sh
deno run <permission flag> npm:<package name>@<version (optional)> <args>
```

## node_modules 的处理

默认情况下，执行 deno run 的时候，deno 不会创建 node_modules，依赖将安装到全局缓存中，这是 deno 推荐的方式。

如果项目中需要 node_modules，可以在 `deno.json` 中配置：

```json
{
  "nodeModulesDir": "auto"
}
```

auto 模式会在项目目录下创建 node_modules，并尝试从全局缓存中拉取需要的包到 node_modules 中。

此外，`nodeModulesDir` 也可以被设置为 `manual`，这个模式下执行 `deno run` 时，deno 不会自动安装相关的依赖，用户必须手动调用 `deno install` 或者 `npm install` 来显示指定的进行包安装，安装后的包也会被放在项目的 `node_modules` 中。手动模式是项目使用 package.json 时的默认模式。

## 缓存位置

使用 `deno info` 指令可以输出 deno 的缓存信息：

```
DENO_DIR location: /Users/xxx/Library/Caches/deno
Remote modules cache: /Users/xxx/Library/Caches/deno/remote
npm modules cache: /Users/xxx/Library/Caches/deno/npm
Emitted modules cache: /Users/xxx/Library/Caches/deno/gen
Language server registries cache: /Users/xxx/Library/Caches/deno/registries
Origin storage: /Users/xxx/Library/Caches/deno/location_data
Web cache storage: /var/folders/0y/7qqcbbvn2k74zkvd46d0582w0000gn/T/deno_cache
```

默认情况下，deno 使用 DENO_DIR  来缓存下载的依赖。

# JSR

JSR 是 NPM 的继任者，JSR 被设计为只支持 ESM，并不支持 CJS。

JSR 并不是想完全取代 NPM，可以理解为 JSR 是 NPM 的超集。

# Deno standard library

Deno 创建了各种标准库来期望统一 Deno 的开发体验，标准库被分发在 JSR 上，大多以 `@std` 为包的命名空间，理论上支持 Node 或者其他的 JS 运行时来调用。

比如：

- @std/testing 取代 jest
- @std/expect 取代 chai
- @std/cli 取代 minimist
- @std/collection 取代 lodash

Before:

![image.png](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202412102142385.png)

After：

![image.png](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202412102143455.png)

# JSR demo

使用标准的 fs 模块可以提供快捷的目录遍历功能：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202412102146018.png)

你可以与 NodeJS 的 fs 模块结合使用：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202412102147183.png)

如果想要发布包到 jsr，只需要在 jsr 上创建项目并复制需要的 deno.json 文件到本地，并运行 `deno publish` 即可。

需要注意，如果发布 jsr 包，则需要在代码中指定依赖包的版本：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202412102152265.png)

JSR 支持根据代码中书写的 JSDoc 来自动生成在线文档：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202412102153143.png)

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202412102154590.png)

# Workspace and monorepo

deno 的 workspace 与 npm 的相似。

deno 还支持 package.json 和 deno.json 的共存：

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202412102157314.png)

# Long term support

![image.png|400](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202412102158584.png)

# Deno is fast

![image.png](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202412102200369.png)


