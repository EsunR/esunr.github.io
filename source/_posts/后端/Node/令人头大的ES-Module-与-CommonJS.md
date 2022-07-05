---
title: 令人头大的ES Module 与 CommonJS
tags: []
categories:
  - 后端
  - Node
date: 2021-07-20 19:00:04
---

# 1. ES Module 与 CommonJS 的概念

模块化编程是个老生常谈的问题了，Javascript 有着沉重的模块化历史包袱，之前引入 Javascript 代码只能通过 Script 标签引入，这样就容易产生如下的问题：

*   js文件作用域都是顶层，这会造成变量污染
*   js文件多，变得不好维护
*   js文件依赖问题，稍微不注意顺序引入错，代码全报错

于是为了解决上述的问题，Javascript 的社区上首先出现了名为 CommonJS 的规范，NodeJS 在 v13.2.0 之前就是基于 CommonJS 规范实现模块化的。但是 CommonJS 只是一个规范，并不是浏览器下的一个功能，因此如果要将 CommonJS 规范应用与前端开发，那还必须要有构建工具的参与,常用的如 [browserify](https://browserify.org/)，通过对入口代码的打包编译，生成一个 `bundle.js` 文件引入到 HTML 页面中。

随着 Javascript 语言的逐渐发展，模块化是其必然的一个趋势，因此在 ES6 里，Javascript 引入了可以使用 `import` `export` 简洁语句来实现模块化的 [ES Module](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Guide/Modules) 概念，我们可以创建一个 `<script type="module" src="xxx.js"></script>` 标签来引入一个使用了 ES Module 规则的 js 文件，从浏览器端实现了模块化编程的问题。

> 但是在实际的开发过程中，如果我们使用了框架就会发现 CommonJS 与 ES Module 可以混合使用，这其实是打包工具在帮助我们做转化，具体的转化原理可以参考这篇文章：[import、require、export、module.exports 混合使用详解](https://www.huaweicloud.com/articles/e71a6bf0e3f114f1ccac4dfcaf57fe76.html)

ES Module 与 CommonJS 都是模块化的解决方案，但是两种方式还是有很大差别的，接下来我们就会来对其差别进行一个更为详细的讨论。

# 2. 使用方式的区别

## 2.1 CommonJS

基础使用：

创建模块：

```js
// module_a.js
var x = 5;
var addX = function (value) {
  return value + x;
};
exports.x = x;
exports.addX = addX;
```

使用模块：

```js
const module_a = require("./module_a.js")
module_a.addX(233)
```

在 CommonJS 规范中，我们来通过对 `exports` 对象上追加多个属性，当其他 js 文件引入该模块时，实际上就是获取了模块的 `exports` 对象，并调用对象上的各个方法。

同时我们还会发现有时 CommonJS 的模块导出会写为：

```js
module.exports.x = x
```

这其实与使用 `exports` 方式导出对象并无差异，只不过是我们可以在模块内部使用 `module` 来获取到整个 `module` 对象，而 `module` 对象上又挂载着 `exports` 对象。`exports` 对象就表示模块对外输出的值，其他文件加载该模块，实际上就是读取 `module.exports` 变量。

使用 `module.exports` 也可以优化我们模块导出的写法，比如：

```js
// module_a.js
var x = 5;
var addX = function (value) {
  return value + x;
};
module.exports = {
  x,
  addX
}
```

同时 `module` 对象上还有其他属性：

*   `module.id` 模块的识别符，通常是带有绝对路径的模块文件名。
*   `module.filename` 模块的文件名，带有绝对路径。
*   `module.loaded` 返回一个布尔值，表示模块是否已经完成加载。
*   `module.parent` 返回一个对象，表示调用该模块的模块。
*   `module.children` 返回一个数组，表示该模块要用到的其他模块。
*   `module.exports` 表示模块对外输出的值。

## 2.2 ES Module

暂略

# 3. 对于值的引用

## 3.1 CommonJS

对于 CJS，看了很多文章，对其形容比较晦涩，我们举例来说明，可总结为以下几点：

**1\. 如果导出的值是基本类型，会对该值进行复制，不与外部共享该值**

比如：

```js
// mod.js
let data = 1

function modifyData() {
  data = 100
}

function printData() {
  console.log(data);
}
module.exports = {
  data, // 这里导出的仅仅是对变量 data 的拷贝
  modifyData,
  printData
}
```

```js
// index.js
const mod = require("./mod.js")
console.log(mod.data); // 1
mod.modifyData() // (1) 执行该语句后，mod.js 中的变量 data 会被修改
console.log(mod.a); // 由于导出模块时，data 是一个基本类型值，module.exports 对象对变量 data 进行了一个浅拷贝，所以输出值仍然是 1
mod.printData(); // 打印出 mod.js 内部的变量 data，由于前面被语句 (1) 修改了，所以输出 100
```

**2\. 如果导出的值是引用类型，会对该值进行浅拷贝，与外部共享该值**

比如：

```js
// mod.js
let data = [1, 2, 3]

function modifyData() {
  data[0] = null
}

function printData() {
  console.log(data);
}

module.exports = {
  data, // 由于 data 是引用类型，所以这里导出的是对 data 的引用
  modifyData,
  printData
}
```

```js
// index.js
const mod = require("./mod.js")
console.log(mod.data); // [1, 2, 3]
mod.modifyData() // 执行该语句后，mod.js 中的变量 data 的值会被修改
console.log(mod.data); // 由于导出的值是对变量 data 的引用，因此输出修改后的 data：[null, 2, 3]
mod.printData(); // [null, 2, 3]
```

**3\. 工作空间可以修改引入的值**

CJS 并未对内部的变量进行保护，因此在使用模块时，可以修改模块导出的值。但是要注意，由于 CJS 导出的值会被缓存，当修改了导出的值后，会影响到其他模块对该值的引用：

```js
// mod.js
let data = 1

module.exports = {
  data
}
```

```js
// utils.js
const mod = require("./mod.js")

exports.printData = function() {
  console.log(mod.a);
}
```

```js
// main.js
const mod = require("./mod.js")
const utils = require("./mod.js")
utils.printData() // 1
mod.data = 100
utils.printData() // 100
```

其实我觉得大可不必想的这么复杂，对于 CJS 我们要清楚其只是导出了一个 `module.exports` 对象，对于这个对象中

## 3.2 ES Module

相对于 CJS 导出的是一个 `exports` 对象，ESM 我们可以理解为导出的是模块内声明的各种变量。其最大的一个特点就是，导出的值是只读的，不能从外部修改，但是可以调用内部方法对其进行修改，比如：

```js
// module.js
export let data = 1
export function addData() {
  data += 1
}
```

```js
// index.js
import { a, modifyData } from "./module.js";

console.log(data); // 1
addData()
console.log(data); // 2
data = 100 // TypeError: Assignment to constant variable.
```

这时候有的小聪明就要问了，你这里用的是解构赋值，赋值给了一个 constance 变量，如果我使用 `import * as xxx` 来直接获取导出对象，修改导出对象上的值能修改成功吗？不妨来试一下：

```js
// index.js
import * as testModule from "./module.js";
testModule.data = 100 // TypeError: Cannot assign to read only property 'data' of object '[object Module]'
```

我们可以看出，导出的模块在本质上就是一个不可修改的值。

# 4. 模块导入的执行顺序与循环引用

## 4.1 CommonJS

CJS 在模块引用时有一个重要的特性就是 **加载时执行**，的执行规则是沿着入口文件开始，逐次向下执行，遇到 `require` 语句后执行 require 的模块的内部代码；

如果在模块内部又再次遇到 `require` 语句，会将当前的代码缓存住，同时检查该模块是否有被引用过（也就是是否存在缓存），这就需要分为两种情况：

1. 如果 require 的模块之前未被引用过，则暂停当前模块的解析，进入新的模块，并执行新模块内部的代码
2. 如果 require 的模块之前被因用过，则无视该 require 语句，继续向下执行

这种引用方式，可以让 CJS 避免循环引用造成代的码锁死，但是也会造成引用顺序不当从而导致某些模块的变量未被创建就本引用的问题。

以下的这个示例就能很好的展示 CJS 的模块引用顺序：

```js
// index.js
let a = require('./modA.js')
let b = require('./modB.js')
console.log('index.js-1', '执行完毕', a.done, b.done)

// modA.js
exports.done = false
let b = require('./modB.js')
exports.data = 100
console.log('modA.js-1', b.done)
exports.done = true
console.log('modB.js-2', '执行完毕')

// modB.js
exports.done = false
let a = require('./modA.js')
console.log('modB.js-1', a.done)
console.log("modB.js-1", a.data);
exports.done = true
console.log('modB.js-2', '执行完毕')

/*
modB.js-1 false
modB.js-1 undefined
modB.js-2 执行完毕
modA.js-1 true
modB.js-2 执行完毕
index.js-1 执行完毕 true true
*/
```

执行图解如下：

![](https://i.loli.net/2021/07/21/QX9zCH3Zq72xcuy.png)

## 4.2 ES Module

ES6模块的运行机制与 CommonJS 不太一样，它遇到模块加载命令 `import` 时，生成的是一个引用，等到真正是用的时候才会去取值.

ES6模块不会缓存运行结果，而是动态地去被加载的模块取值，以及变量总是绑定其所在的模块。这导致 ES6 处理"循环加载"与 CommonJS 有本质的不同。ES6根本不会关心是否发生了"循环加载"，只是生成一个指向被加载模块的引用，需要开发者自己保证，真正取值的时候能够取到值。

举例来说：

```js
// a.js
import { bar } from "./b.js";
export function foo() {
  bar();
  console.log("执行完毕");
}
foo();
```

```js
// b.js
import { foo } from "./a.js";
export function bar() {
  // 设置一定概率跳出循环，避免堆栈溢出
  if (Math.random() > 0.5) {
    foo(); // 代码执行到 foo 时才去访问导入的 foo 函数
  }
}
```

代码可以正常执行，会输入随机概率个 `执行完毕`。

然而如果换成 CJS 的写法，代码是无法运行的：

```js
// a_cjs.js
const bar = require("./b_cjs.js").bar;
function foo() {
  bar();
  console.log("执行完毕");
}
module.exports = {
  foo,
};
foo();
```

```js
// b_cjs.js
const foo = require("./a_cjs.js").foo;
function bar() {
  // 设置一定概率跳出循环，避免堆栈溢出
  if (Math.random() > 0.5) {
    foo(); // 代码按顺序加载到该行时，由于 a_cjs.js 为执行完毕，所以此处的取值是 undefined，代码无法执行
  }
}
module.exports = {
  bar,
};
```

