---
title: 简述Javascript的类型判断
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

# 2. instanceof 

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

上面第一组的解析我们很容易就能明白，因为一个对象本身的隐式原型与其显示原型不相等，那么肯定返回 `false`；第二组，Foo 函数构造于 `Function` 这是一个很标准的原型继承；而第三组似乎有些特殊，但是仔细看一下原型继承图我们就很容易看明白，对于 Object 来说 `Object.__proto__.proto__ === Object.prototype`，对于 Function 来说 `Function.__proto__ === Function.prototype`。

[](!http://markdown.img.esunr.xyz/20191109222853.png)

# 3.Object.prototype.toString()

### 被改写的 toString()

由于 Object 对象的原型上挂载了一个 `toString()` 方法，因此根据原型链的调用规则，在 Javascript 中每个对象都可以调用 `toString()` 方法，其本身原意为返回一个表示该对象的字符串。

我们可以通过创建一个对象来调用该方法：

```js
let obj = new Object()
console.log(obj.toString()) // '[object Object]'
```

但是当我们调用 Number 类型或者 Array 类型时，其结果为：

```js
let num = 123
console.log(num.toString()); // '123'
console.log([1,2,3].toString()); // '1,2,3'
```

这是由于在 `Number.prototype` 与 `Array.prototype` 上已经改写了 `toString()` 方法，`123.toString()` 执行的其实是 `Number.prototype.toString()` 而并非 `Object.prototype.toString()`。对于大部分的 Javascript 内建类型来说，都改写了 `toString()` 方法，用户自行创建的构造函数也可以通过在 `prototype` 上挂载 `toString()` 方法达到改写的目的。以下的表格列举了常见的类型对象调用 `toString()` 方法所输出的结果：

| 数据类型  | 例子                 | return                                                           |
| --------- | -------------------- | ---------------------------------------------------------------- |
| 字符串    | "foo".toString()     | "foo"                                                            |
| 数字      | 1.toString()         | Uncaught SyntaxError: Invalid or unexpected token                |
| 布尔值    | false.toString()     | "false"                                                          |
| undefined | undefined.toString() | Uncaught TypeError: Cannot read property 'toString' of undefined |
| null      | null.toString()      | Uncaught TypeError: Cannot read property 'toString' of null      |
| String    | String.toString()    | "function String() { \[native code\] }"                          |
| Number    | Number.toString()    | "function Number() { \[native code\] }"                          |
| Boolean   | Boolean.toString()   | "function Boolean() { \[native code\] }"                         |
| Array     | Array.toString()     | "function Array() { \[native code\] }"                           |
| Function  | Function.toString()  | "function Function() { \[native code\] }"                        |
| Date      | Date.toString()      | "function Date() { \[native code\] }"                            |
| RegExp    | RegExp.toString()    | "function RegExp() { \[native code\] }"                          |
| Error     | Error.toString()     | "function Error() { \[native code\] }"                           |
| Promise   | Promise.toString()   | "function Promise() { \[native code\] }"                         |
| Obejct    | Object.toString()    | "function Object() { \[native code\] }"                          |
| Math      | Math.toString()      | "\[object Math\]"                                                |


那如果我们想强制让某一对象调用 `Object.prototype.toString()` 方法会发生什么呢？我们使用 `call` 来改写方法中的 `this` 可以达到这一效果：

```js
let num = 123
console.log(Object.prototype.toString.call(num)); // '[Object Number]'
```

可以发现通过借助 `Object.prototype.toString()` 我们可以获取到调用对象的类型，这一点非常有用，可以帮助我们接下来进行类型判断。

### 内部原理

在编写类型判断的方法之前，我们不妨来看一下 `Object.prototype.toString` 到底做了什么，在不同的 ES 版本中，该方法会有一定的区别：

ES5 环境下：

*   如果**this**的值为**undefined**,则返回`"[object Undefined]"`.
*   如果**this**的值为**null**,则返回`"[object Null]"`.
*   让*O*成为调用ToObject(**this**)的结果.
*   让*class*成为*O*的内部属性\[\[Class\]\]的值.
*   返回三个字符串**"\[object ",** *class*, 以及 **"\]"**连接后的新字符串.

ES6 环境下：

*   如果**this**的值为**undefined**,则返回`"[object Undefined]"`.
*   如果**this**的值为**null**,则返回`"[object Null]"`.
*   让*O*成为调用ToObject(**this**)的结果.
*   如果*O*有\[\[NativeBrand\]\]内部属性,让*tag*成为表29中对应的值.
*   否则
    1.  让*hasTag*成为调用*O*的\[\[HasProperty\]\]内部方法后的结果,参数为@@toStringTag.
    2.  如果*hasTag*为**false**,则让*tag*为`"Object"`.
    3.  否则,
        1.  让*tag*成为调用*O*的\[\[Get\]\]内部方法后的结果,参数为@@toStringTag.
        2.  如果*tag*是一个abrupt completion,则让*tag*成为NormalCompletion(`"???"`).
        3.  让*tag*成为*tag*.\[\[value\]\].
        4.  如果Type(*tag*)不是字符串,则让*tag成为*`"???"`.
        5.  如果*tag*的值为`"Arguments"`, `"Array"`, `"Boolean"`, `"Date"`, `"Error"`, `"Function"`, `"JSON"`, `"Math"`, `"Number"`, `"Object"`, `"RegExp"`,`或者"String"中的任一个,则让`*tag*成为字符串`"~"和`*tag*当前的值连接后的结果.
*   返回三个字符串"\[object ", tag, and "\]"连接后的新字符串.

### 封装一个类型判断的方法

```js
function type (data){
  if(arguments.length === 0) return new Error('type方法未传参');
  var typeStr = Object.prototype.toString.call(data);
  return typeStr.match(/\[object (.*?)\]/)[1].toLowerCase();
}
```