---
title: 如何在 CJS 中使用 ES Module
tags:
  - esm
  - cjs
categories:
  - 前端
  - Javascript
date: 2024-08-08 16:12:25
---
# 1. 前言

在 Nodejs 中，我们可以使用 `import` 来引入 CommonJS 和 ESM 的包，但是无法使用 `require` 来引入 ESM 规范的包，此时会出现 `ERR_REQUIRE_ESM` 的报错。

>  让我看看那哪个语言有两种包引入规范还不互相兼容，哦原来是 NodeJS

为了解决 NodeJS 中存在两种包引入规范的问题，大部分的公共包作者会利用构建工具将自己的包编译成两份，并在 `package.json` 中声明对应 CJS 规范和 ESM 规范包锁在的位置。但是随着时间的推移，越来越多的公共包开发者不想再为 NodeJS 的这一特性买单，因此他们放弃了同时兼容多个包引入规范，而是专心使用 ESM 规范来进行开发（比如 [execa](https://github.com/sindresorhus/execa)）。这就导致如果我们的项目基于 CommonJS 规范编写，就无法使用这些包。

 针对为什么 `require` 不支持引入 ESM 规范的包，之前有很多人的解释是 `import` 是异步的，所以不能支持。但事实上支持与否并不是技术问题，而是观念问题（可以看看[这篇文章](https://joyeecheung.github.io/blog/2024/03/18/require-esm-in-node-js/)，讨论了 NodeJS 之前为什么不支持 `require` 方法来引用 ESM 规范的模块），其完全是可实现的，在 [Node 22](https://nodejs.org/en/blog/announcements/v22-release-announce#support-requireing-synchronous-esm-graphs) 中使用 `--experimental-require-module` 就可以开启 `require` 对 ESM 的支持。

# 2. 解决问题

对于很多旧的项目，将 CJS 转为 ESM 可能涉及的工作量很大，亦或是如果项目使用 Typescript，还会有很多人不会留意到即使使用了 `import` 写法，Typescript 最终也会根据默认配置将编译后的代码转为 `require` 写法。

因此最好无痛的让我们可以在 CommonJS 规范的项目中使用 ESM。

这也不是完全没有办法，很重要的一点是，虽然我们不能在 CJS 规范下使用 `import` 关键字来引入模块（会出现 `(node:31838) Warning: To load an ES module, set "type": "module" in the package.json or use the .mjs extension.` 的错误），但是不代表我们不能使用 `import`  方法呀。

`import` 是一个异步的方法，可以正常的解析 ESM 和 CJS 规范的包内容，并将包的导出内容作为结果进行返回，因此我们只需要异步的调用该方法即可：

```js
(async () => {
    const { add } = await import("./esm/utils.mjs");
    add(1, 2);
})();
```

但是假如我们使用了 Typescript，前面我们也说了，在默认情况下 TS 会将你写的 `import` 语法转为 `require` 语法（可能是出于性能考虑，`require` 引入模块的性能优于 `import`），对于异步的 `import` 方法，Typescript 会“贴心”的将其转为 `__importStar` 方法，并仍然用 `require` 语法来对包进行引入。

```ts
(() => __awaiter(void 0, void 0, void 0, function* () {
    const { add } = yield Promise.resolve().then(() => __importStar(require("./esm/utils.mjs")));
    add(1, 2);
}))();
```

因此在这种情况下，我们不得不使用 `eval` 来执行代码了，Typescript 的代码应写为：

```ts
(async () => {
    const { add } = await (eval(`import("./esm/utils.mjs")`) as Promise<{
        add: Function;
    }>);
    add(1, 2);
})();
```

这样编译后的代码就不会被 Typescript 偷偷转换了~