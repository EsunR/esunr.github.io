---
title: 字节跳动面试记录（四）
categories:
  - 面试
date: 2024-03-26 20:32:20
tags:
---

### 讲一下 HTTP 和 HTTPS

### HTTP 1.0 和 HTTP 2.0 区别

### HTTP 2.0 如何实现二进制帧封装的

### HTTP 2.0 服务器推送和多路复用的弊端是什么

### 写一个深拷贝，需要考虑边缘情况（循环引用）

```js
function deepClone(obj, map = new Map()) {
  if (!(typeof obj === "object" && obj !== null)) {
    return obj;
  }
  if (map.get(obj)) {
    return map.get(obj);
  }
  const newObj = obj instanceof Array ? [] : {};
  map.set(obj, newObj);
  for (let key in obj) {
    newObj[key] = obj[key];
  }
  return newObj;
}
```

### 讲一下箭头函数，以及它的 this 指向

```js
window.name = 'window'

const a = {
    name: 'A',
    b: function() {
         return () => {
            console.log(this.name) 
         }
     }   
}

const b = {
    name: "B"
}

const arrowFunc = a.b();
arrowFunc(); // 'A'
arrowFunc.call(b); // 'A'
arrowFunc.call(); // 'A'
```

这道题被坑了，要坚定箭头函数的 this 指向是声明函数时上下文的 this，并且无法被强绑定修改指向！！！！除非 ：

```js
const arrowFunc = a.b;
arrowFunc()(); // 'window'
arrowFunc.call(b)(); // 'B'
arrowFunc.call()(); // 'window'
```

### Promise 有什么作用，解决了什么难点

### Promise 上挂载的几个静态方法有什么区别

### 实现一个 Promise.all
