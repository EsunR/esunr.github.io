基于视频：[Announcing Deno 2](https://www.youtube.com/watch?v=d35SlRgVxT8&t=626s)

# Package Manager

deno 拥有 npm 一样的包管理指令：

- deno install
- deno add
- deno remove

当项目存在 pacakge.josn 时，deno 会在项目中创建 node_modules 来进行依赖缓存。

如果没有 package.json，deno 会读取 deno.json 并从全局缓存中进行查找或安装。

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
