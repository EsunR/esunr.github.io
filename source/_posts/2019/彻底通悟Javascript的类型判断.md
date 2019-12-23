---
title: 彻底通悟Javascript的类型判断
tags: [JS]
categories:
  - Front
  - JS
date: 2019-12-23 23:40:14
---

# 1. typeof

typeof 是 Javascript 的一个操作符，可以表示未经计算的操作数的类型。

如下是摘录自 MDN 的 `typeof` 可能输出的值的列表：

| 类型                                                                                                               | 结果             |
| ------------------------------------------------------------------------------------------------------------------ | ---------------- |
| [Undefined](https://developer.mozilla.org/en-US/docs/Glossary/Undefined)                                           | `"undefined"`    |
| [Null](https://developer.mozilla.org/en-US/docs/Glossary/Null)                                                     | `"object"`       |
| [Boolean](https://developer.mozilla.org/en-US/docs/Glossary/Boolean)                                               | `"boolean"`      |
| [Number](https://developer.mozilla.org/en-US/docs/Glossary/Number)                                                 | `"number"`       |
| [BigInt](https://developer.mozilla.org/en-US/docs/Glossary/BigInt)                                                 | `"bigint"`       |
| [String](https://developer.mozilla.org/en-US/docs/Glossary/String)                                                 | `"string"`       |
| [Symbol](https://developer.mozilla.org/en-US/docs/Glossary/Symbol) (ECMAScript 2015 新增)                          | `"symbol"`       |
| 宿主对象（由 JS 环境提供）                                                                                         | *取决于具体实现* |
| [Function](https://developer.mozilla.org/en-US/docs/Glossary/Function) 对象 (按照 ECMA\-262 规范实现 \[\[Call\]\]) | `"function"`     |
| 其他任何对象                                                                                                       | `"object"`       |

使用 `typeof` 时要特别注意以下两个非预想的结果：

- `typeof null` 输出为 "object"
- `typeof NaN` 输出为 "number" (NaN：Not-A-Number)

此外 MDN 附加了以下 `typeof` 的诡异特性，在此进行摘录：

### `null`

```
// JavaScript 诞生以来便如此
typeof null === 'object';
```

在 JavaScript 最初的实现中，JavaScript 中的值是由一个表示类型的标签和实际数据值表示的。对象的类型标签是 0。由于 `null` 代表的是空指针（大多数平台下值为 0x00），因此，null 的类型标签是 0，`typeof null` 也因此返回 `"object"`。（[参考来源](http://www.2ality.com/2013/10/typeof-null.html)）

曾有一个 ECMAScript 的修复提案（通过选择性加入的方式），但[被拒绝了](http://wiki.ecmascript.org/doku.php?id=harmony:typeof_null)。该提案会导致 `typeof null === 'null'`。

### 使用 `new` 操作符

```js
// 除 Function 外的所有构造函数的类型都是 'object'
var str = new String('String');
var num = new Number(100);

typeof str; // 返回 'object'
typeof num; // 返回 'object'

var func = new Function();

typeof func; // 返回 'function'
```

### 语法中的括号

```js
// 括号有无将决定表达式的类型。
var iData = 99;

typeof iData + ' Wisen'; // 'number Wisen'
typeof (iData + ' Wisen'); // 'string'
```

### 正则表达式

对正则表达式字面量的类型判断在某些浏览器中不符合标准：

```js
typeof /s/ === 'function'; // Chrome 1-12 , 不符合 ECMAScript 5.1
typeof /s/ === 'object'; // Firefox 5+ , 符合 ECMAScript 5.1

```

### 错误

在 ECMAScript 2015 之前，`typeof` 总能保证对任何所给的操作数返回一个字符串。即便是没有声明的标识符，`typeof` 也能返回 `'undefined'`。使用 `typeof` 永远不会抛出错误。

但在加入了块级作用域的 [let](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Statements/let) 和 [const](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Statements/const) 之后，在其被声明之前对块中的 `let` 和 `const` 变量使用 `typeof` 会抛出一个  [ReferenceError](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/ReferenceError)。块作用域变量在块的头部处于“[暂存死区](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Statements/let#Temporal_Dead_Zone_and_errors_with_let)”，直至其被初始化，在这期间，访问变量将会引发错误。

```js
typeof undeclaredVariable === 'undefined';

typeof newLetVariable; // ReferenceError
typeof newConstVariable; // ReferenceError
typeof newClass; // ReferenceError

let newLetVariable;
const newConstVariable = 'hello';
class newClass{};
```

### 例外

当前所有的浏览器都暴露了一个类型为 `undefined` 的非标准宿主对象 [`document.all`](https://developer.mozilla.org/zh-CN/docs/Web/API/Document/all "Document 接口上的一个只读属性。返回一个 HTMLAllCollection，包含了页面上的所有元素。")。

```js
typeof document.all === 'undefined';

```

尽管规范允许为非标准的外来对象自定义类型标签，但它要求这些类型标签与已有的不同。`document.all` 的类型标签为 `'undefined'` 的例子在 Web 领域中被归类为对原 ECMA JavaScript 标准的“故意侵犯”。

# instanceof 

instanceof 运算符用于检测构造函数的 prototype 属性是否出现在某个实例对象的原型链上，换句话说，instanceof 可以帮助我们来判断一个对象是否是否继承与另一个对象。

其实这里可以看一下 `instanceof` 运算符代码：

```js
function instance_of(L, R) {//L 表示左表达式，R 表示右表达式
 var O = R.prototype;// 取 R 的显示原型
 L = L.__proto__;// 取 L 的隐式原型
 while (true) { 
   if (L === null) 
     return false; 
   if (O === L)// 这里重点：当 O 严格等于 L 时，返回 true 
     return true; 
   L = L.__proto__; 
 } 
}
```

可以很容易发现，`instance_of` 方法取出了右边对象 R 的 `prototype` 属性，然后使用了 `while` 循环一层一层的去调出左边对象 L 的 `__proto__` 隐式原型，按照原型链的调用规则，如果 L 继承与 R ，那 L 在某一层的隐式原型一定与 R 的显示原型完全相等。

举个例子：

```js
console.log(Number instanceof Number);//false 
console.log(String instanceof String);//false 
console.log(Function instanceof Object);//true 
console.log(Foo instanceof Foo);//false

console.log(Foo instanceof Function);//true 

console.log(Object instanceof Object);//true 
console.log(Function instanceof Function);//true 
```

上面第一组的解析我们很容易就能明白，因为一个对象本身的隐式原型与其显示原型不相等，那么肯定返回 `false`；第二组，Foo 函数构造于 `Function` 这是一个很标准的原型继承；而第三组似乎有些特殊，但是仔细看一下原型继承图我们就很容易看明白：

[](!http://markdown.img.esunr.xyz/20191109222853.png)