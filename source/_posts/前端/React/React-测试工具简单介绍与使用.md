---
title: React 测试工具简单介绍与使用
tags:
  - React
  - Jest
  - 软件测试
categories:
  - 前端
  - React
date: 2020-07-12 00:54:05
---

# 1. 通用测试工具 Jest

> Jest 是一个 JavaScript 测试运行器。它允许你使用 jsdom 操作 DOM 。尽管 jsdom 只是对浏览器工作表现的一个近似模拟，对测试 React 组件来说它通常也已经够用了。Jest 有着十分优秀的迭代速度，同时还提供了若干强大的功能，比如它可以模拟 modules 和 timers 让你更精细的控制代码如何执行。

## 1.1 启动测试

create-react-app 中内置了 jest ，我们可以直接使用 `npx` 来执行测试指令。

全局运行 jest 指令：

```sh
$ npx jest
```

如果要测试单个文件，运行：

```sh
$ npx jest xxx.js
```

测试某个文件并开启监听修改：

```sh
$ npx jest xxx.js --watch
```

## 1.2 使用断言进行测试

使用 `toBe()` 测试结果是否符合预期：

```js
test("test common matcher", () => {
  expect(2 + 2).toBe(4);
  expect(2 + 2).not.toBe(6);
});
```

使用 `toBeTruthy()` 与 `toBeFalsy()` 测试布尔值结果是否符合预期：

```js
test("test not to be true or false", () => {
  expect(1).toBeTruthy();
  expect(0).toBeFalsy();
});
```

使用 `toBeGreaterThan()` 与 `toBeLessThan()` 比较数字结果大小：

```js
test("test number", () => {
  expect(4).toBeGreaterThan(3);
  expect(2).toBeLessThan(3);
});
```

使用 `toEqual()` 测试结果值是否相等，可以用来判断对象结果：

```js
test("test object", () => {
  expect({ name: "esunr" }.toEqual({ name: "esunr" }));
});
```

# 2. React 测试库

> React 测试库是一组能让你不依赖 React 组件具体实现对他们进行测试的辅助工具。它让重构工作变得轻而易举，还会推动你拥抱有关无障碍的最佳实践。虽然它不能让你省略子元素来浅（shallowly）渲染一个组件，但像 Jest 这样的测试运行器可以通过 mocking 让你做到。

最新版本的 create-react-app 内置了 @testing-library/react 可以用来专门进行 React 测试。

jest 会自动对以下文件运行测试：

1. `__tests__` 文件夹下的 `.js` 文件
2. 以 `.test.js` 为后缀的文件
3. 以 `.spec.js` 为后缀的文件

> jest 不仅支持 ts 文件还支持 ts 文件

因此我们可以在组件文件夹下创建 `Button.test.tsx` 文件作为 Button 组件的测试文件：

```js
import React from "react";
import { render } from "@testing-library/react";
import Button from "./button";

test("first test", () => {
  const wrapper = render(<Button>Nice</Button>);
  const element = wrapper.queryByText("Nice");
  expect(element).toBeTruthy();
});
```
# 3. jest-dom

jest-dom 是 test library 开发的测试工具，可以为 jest 断言库添加更多的针对 dom 的断言，最新版本的 create-react-app 已经内置了这一工具。

create-react-app 支持在 src 目录下创建 `setupTests.ts` 文件，在运行 `npm run test` 时首先执行该文件。，因此可以用来在做测试前存放全局的通用文件。

要使用 jest-dom 首先要在 `setupTests.ts` 将其引入：

```ts
// setupTests.ts
import "@testing-library/jest-dom/extend-expect";
```

之后我们便可以在测试中使用 jest-dom 的断言库：

```ts
import React from "react";
import { render } from "@testing-library/react";
import Button from "./button";

test("first test", () => {
  const wrapper = render(<Button>Nice</Button>);
  const element = wrapper.queryByText("Nice");
  // expect(element).toBeTruthy();
  expect(element).toBeInTheDocument();
});
```
