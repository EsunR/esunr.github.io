---
title: 重拾JSONP，手动封装JSONP的多种写法
tags: [面试题]
categories:
  - Front
  - JS
date: 2019-11-27 22:19:28
---

# 1. JSONP 原理以及传统的实现方案

在如今的前后端分离传递数据的方式下，大多解决跨域的方案都使用设置 CORS（跨域资源共享），但是 jsonp 由于可以兼容低版本浏览器，现在仍然还有在使用，同时其实现思路也比较有意思，所以在此记录一下。

jsonp 的实际原理就是客户端通过 `script` 标签的 `src` 属性向服务器发送一个 get 请求，服务器端返回一个格式为 `Content-Type: text/javascript; charset=utf-8` 的响应数据。换句话说就是从服务器引入一个脚本文件，由于 `script` 标签不受同源策略的影响，因此可以按照这种方式来进行跨域的数据传输。

服务器返回的数据通常为一个引用函数，如：

```js
callback({ name: "huahua", age: 18 })
```

我们以 Express 框架为例，设置一个 jsonp 请求服务器：

```js
// serve.js 
const express = require("express");
const app = express();

app.get("/jsonp", function(req, res) {
  res.jsonp({
    name: "huahua",
    age: 19
  });
});

app.listen(3000, function() {
  console.log(`serve on http://localhost:3000`);
});
```

当浏览器访问 `http://localhost:3000/jsonp?callback=test` ，就会获取如下数据：

![20191127223441.png](https://i.loli.net/2019/11/27/bgpV9FqtOLThiek.png)

所以基本流程就是：

1. 客户端编写一个回调函数
2. 向 `<head></head>` 标签中加入一个 `script` 标签，标签的 url 为请求 jsonp 数据的地址
3. 引入的 `script` 脚本执行回调函数

因此我们可以编写一个最原始的请求方案：

```html
<html>

<head>
<!-- ...... -->
  <script>
    function callback(data) {
      document.querySelector(".data").innerHTML += JSON.stringify(data)
    }
    function getdata() {
      const script = document.createElement("script")
      script.src = `${options.url}?callback=${options.cbName}${queryString}`
      document.head.appendChild(script)
    }
  </script>
</head>

<body>
  <button onclick="getdata()">get data</button>
  <div class="data"></div>
</body>

</html>
```

效果如下：

![等待点击按钮](https://i.loli.net/2019/11/27/Ox4QEmaMXhNYq3J.png)

![点击按钮获取数据](https://i.loli.net/2019/11/27/sRIo63wegvtPZ1C.png)

# 2. 封装方案

## 2.1 JsonpRequest 对象

```js
class JsonpRequest {
  constructor(url, cb, query, cbName = "callback") {
    this.url = url
    this.cb = cb
    this.cbName = cbName
    this.query = query
    this.queryString = ""
    if (this.query) {
      for (let key in query) {
        this.queryString += `&${key}=${query[key]}`
      }
    }
  }
  get() {
    window[this.cbName] = this.cb
    const script = document.createElement("script")
    script.src = `${this.url}?callback=${this.cbName}${this.queryString}`
    document.head.appendChild(script)
  }
}
```

使用方法：

```js
function getdata() {
  const jsonpReq = new JsonpRequest(
    "http://localhost:3000/jsonp", 
    function (data) {
      document.querySelector(".data").innerHTML += JSON.stringify(data)
    }
  )
  jsonpReq.get()
}
```

## 2. jsonpReq 方法

```js
function jsonpReq(options) {
  let queryString = ""
  if (!options.cbName) {
    options.cbName = "callback"
  }
  if (options.query) {
    for (let key in options.query) {
      queryString += `&${key}=${options.query[key]}`
    }
  }
  window[options.cbName] = options.cb
  const script = document.createElement("script")
  script.src = `${options.url}?callback=${options.cbName}${queryString}`
  document.head.appendChild(script)
}
```

使用方法：

```js
function getdata() {
  jsonpReq({
    url: "http://localhost:3000/jsonp",
    query: { id: 1 },
    cb: function (data) {
      document.querySelector(".data").innerHTML += JSON.stringify(data)
    }
  })
}
```