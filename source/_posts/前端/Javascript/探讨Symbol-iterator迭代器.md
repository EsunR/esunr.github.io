---
title: 探讨 Symbol-iterator 迭代器
tags:
  - 你不知道的Javascript
categories:
  - 前端
  - Javascript
date: 2019-12-27 10:25:14
---

# 1. 何为 Symbol-iterator

> Symbol.iterator 为每一个对象定义了默认的迭代器。该迭代器可以被 for...of 循环使用。

ES6 定义了 `for...of` 方法，可以用来遍历数组的值，其用法如下：

```js
var arr = ["a", "b", "c"];
for (let value of arr) {
  console.log(value);
}
```

```
a
b
c
```

实际上 `for...of` 循环首先会向被访问的对象请求一个 **迭代器对象** ，然后通过调用迭代器对象的 `next()` 方法来遍历所有返回值。所谓的迭代器对象，就是指数组上本身所内置的 `@@iterator` ，我们可以通过访问数组的 `Symbol.iterator` 属性来取到该迭代器：

```js
var arr = ["a", "b", "c"];
arr[Symbol.iterator] // [Function: values]
```

我们可以利用其进行手动遍历数组：

```js
var arr = ["a", "b", "c"];
var it = arr[Symbol.iterator]();
console.log(it.next()); // { value: 'a', done: false }
console.log(it.next()); // { value: 'b', done: false }
console.log(it.next()); // { value: 'c', done: false }
console.log(it.next()); // { value: undefined, done: true }
```

以下对象都内置了迭代器，也就是说他们可以直接使用 `for...of` 循环：

- Array.prototype[@@iterator]()
- TypedArray.prototype[@@iterator]()
- String.prototype[@@iterator]()
- Map.prototype[@@iterator]()
- Set.prototype[@@iterator]()

此外，ES6 的展开运算符也是基于迭代器实现的：

```js
let a = [1,2,3]
console.log([...a]) // [1, 2, 3]
```

# 2. 迭代器的实现

对于一个普通的 Object 来说，由于其没有内置迭代器所以不能使用 `for...of` 循环，但是我们只要手动为其挂载上一个迭代器方法，并让其返回一个 `next()` 方法，每次调用 `next()` 方法是都返回一个包含 `value` 与 `done` 属相的对象，也可以实现对普通对象的 `for...of` 循环：

```js
var obj = {
  0: "a",
  1: "b",
  3: "c"
};

Object.defineProperty(obj, Symbol.iterator, {
  enumerable: true,
  writable: false,
  configurable: true,
  value: function() {
    let o = this;
    let index = 0;
    let keys = Object.keys(o);
    return {
      next: function() {
        return {
          value: o[keys[index++]],
          done: index > keys.length
        };
      }
    };
  }
});

for (let value of obj) {
  console.log(value);
}

console.log([...obj])
```

```
a
b
c
[ 'a', 'b', 'c' ]
```

顺带一提，迭代器每一步返回的过程是不是与 Generator 十分相似，我们先来复习一下 Generator 函数的操作：

```js
function* generatorFn() {
  let a = 0
  yield a++;
  yield a++;
  yield a++;
}

let ge = generatorFn();

console.log(ge.next()); // { value: 0, done: false }
console.log(ge.next()); // { value: 1, done: false }
console.log(ge.next()); // { value: 2, done: false }
console.log(ge.next()); // { value: undefined, done: true }
```

所以利用 Generator 可以更加便捷的实现迭代器：

```js
var obj2 = {
  0: "a",
  1: "b",
  3: "c"
};

Object.defineProperty(obj2, Symbol.iterator, {
  enumerable: true,
  writable: false,
  configurable: true,
  value: function*() {
    let keys = Object.keys(this);
    // 注意 yeild 在这里只能使用 for 循环遍历，而不能使用 yield
    for (let i = 0; i < keys.length; i++) {
      yield this[keys[i]];
    }
  }
});
```