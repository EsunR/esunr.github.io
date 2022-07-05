---
title: 浅谈 Content Security Policy(CSP) 内容安全策略
tags:
  - 网络安全
  - XSS
categories:
  - 前端
  - 浏览器
date: 2021-09-07 19:47:26
---

# 1. 何为 CSP

CSP 是一种有效防止用户浏览器页面安全的一种策略，通过设置 CSP，浏览器能够阻止恶意的 XSS 攻击。

举个例子：

在某一博客类的网站上，用户可以插入任何富文本内容。于是黑客就向页面插入了一个恶意的图片链接，浏览器加载了图片，就发送了一个 GET 请求。但我们无法保证图片的链接是安全的，比如这个 GET 请求会诱骗你关注某个人的博客：

```
http://www.blog.xyz/api?follow_id=123
```

这种攻击方式就是一种常见的 XSS 攻击。

作为一个网站的管理者，假如我们可以有一种白名单机制，仅允许我们的页面上加载白名单域名的资源，其他的资源请求通通拒绝访问，那我们就可以有效避免类似的 XSS 攻击了。这种设置白名单的方式，就是内容限制安全策略，即为 Content Security Policy。

# 2. 如何设置 CSP

那么讲完了何为 CSP，又该如何设置 CSP 呢？

一个安全且标准的浏览器支持两种设置方式：
- 一种是读取 HTML 页面的 `<meta>` 标签中声明的安全策略，这个可以由前端在编写页面时来添加
- 另外一种就是请求 HTML 页面时，读取响应头中的 `Content-Security-Policy` 字段声明的安全策略，这个可以由后台在服务器端添加

## 2.1 在 meta 中声明 CSP

```html
<meta http-equiv="Content-Security-Policy" content="script-src 'self'; object-src 'none'; style-src cdn.example.org third-party.org; child-src https:">
```

上面代码中，CSP 做了如下配置：

*   脚本：只信任当前域名
*   `<object>`标签：不信任任何URL，即不加载任何资源
*   样式表：只信任`cdn.example.org`和`third-party.org`
*   框架（frame）：必须使用HTTPS协议加载
*   其他资源：没有限制

## 2.2 在响应头中声明 CSP

以 express 为例，可以使用 expressCspHeader 中间件：

```js
app.use(expressCspHeader({
    directives: {
        'default-src': [SELF, INLINE, '*.baidu.com', ALLOW_SAME_ORIGIN],
        'script-src': [SELF, INLINE, '*.baidu.com', ALLOW_SAME_ORIGIN, EVAL],
        'style-src': [SELF, INLINE, '*.baidu.com', ALLOW_SAME_ORIGIN],
        'img-src': ['data:', INLINE, '*.baidu.com', ALLOW_SAME_ORIGIN],
        'worker-src': [NONE],
        'block-all-mixed-content': true,
    },
}));
```

请求资源时：

![](https://i.loli.net/2021/09/07/PeVx6HwoEWYUkfZ.png)

当我们页面加载非 `baidu.com` 域名下的图片资源时，就会出现 `Provisional headers are shown` 的错误警告：

![](https://i.loli.net/2021/09/07/3jmMSDXVObHzWyr.png)

# 3. 参考

[MDN - 内容安全策略( CSP )](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/CSP)
[阮一峰 - Content Security Policy 入门教程](http://www.ruanyifeng.com/blog/2016/09/csp.html)
[Chrome Developers - Content Security Policy](https://developer.chrome.com/docs/apps/contentSecurityPolicy/)