---
title: JavaScript浅拷贝与深拷贝
tags:
  - 面试题
categories:
  - 前端
  - Javascript
date: 2019-12-22 12:55:01
---

# 1. 回顾

JavaScript中有6种数据类型：数字（number）、字符串（string）、布尔值（boolean）、undefined、null、对象（Object）。其中对象类型包括：数组（Array）、函数（Function）、还有两个特殊的对象：正则（RegExp）和日期（Date）。

对于引用类型来说其存放于堆内存，当其被做一个 LSH 引用时，其只是引用了堆内存的地址，而并非跟值类型的数据一样开辟一块新内存，所以如果想要拷贝引用类型的数据往往比较繁琐，数组、函数、对象、Map 都属于引用类型。

# 2. 浅拷贝

浅拷贝相当于仅对最外层元素做了拷贝，假如对象中的某个值仍是一个引用类型的值，那么嵌套的这个引用类型将不会被拷贝。

数组的浅拷贝可以使用 `slice()` 来实现，而对象的浅拷贝可以通过遍历对象实现，也可以通过 `Object.assign` 来实现：

```js
function simpleCopy(obj) {
  if (obj instanceof Array) {
    return obj.slice();
  } else if (obj instanceof Object) {
    return Object.assign({}, obj);
  } else {
    return obj
  }
}
```

# 3. 深拷贝

为了弥补浅拷贝的缺点，那么我们就需要对元素进行深拷贝，最简单粗暴的方式就是使用 `JSON.stringify()` 这个方式来将对象转换为字符串，再通过 `JSON.parse()` 来转换。但是这样的话 `undefined` 就会被忽略掉，同时原型链也会丢失，举一个简单的例子：

```js
function Dog(name) {
  this.name = name;
}
Dog.prototype.brak = function() {
  console.log("wangwangwang");
};

let obj = {
  a: 1,
  b: {
    c: 2,
    d: 3
  },
  e: undefined,
  f: null,
  g: new Dog("huahua")
};

let newObj = JSON.parse(JSON.stringify(obj));
console.log("newObj: ", newObj);
newObj.g.brak();
```

输出：

```js
newObj:  { a: 1, b: { c: 2, d: 3 }, f: null, g: { name: 'huahua' } }
TypeError: newObj.g.brak is not a function
```

为了解决这个问题，我们可以使用递归来解决，只要判断每一个值如果是 `Object` 类型，就对其递归进行深拷贝。如下的深拷贝即可实现对原型链方法的拷贝：

```js
function deepClone(obj) {
  let newObj;
  // 获取该对象的类型,如 Function、Array 等
  let type = Object.prototype.toString.call(obj).slice(8, -1);
  console.log('type: ', type);
  if (type === "Array") {
    // 如果深拷贝的对象是一个数组，初始化这个数组
    newObj = [];
  } else if (type === "Object") {
    // 如果深拷贝的对象是一个普通对象
    newObj = {};
  } else {
    // 如果被拷贝的对象既不是 Array 也不是 Object，那么就说明其可能是 Function、RegExp、Date 这种特殊类型，直接返回原值
    return obj;
  }
  for (let key in obj) {
    if (obj[key] instanceof Object) {
      // 如果当前 key 的值是一个 Object 类型，就对该对象进行递归调用
      newObj[key] = deepClone(obj[key]);
    } else {
      newObj[key] = obj[key];
    }
  }
  return newObj;
}
```