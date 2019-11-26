---
title: http与浏览器的缓存机制
tags: []
categories:
  - Other
date: 2019-11-26 23:50:07
---

# 缓存基础

首先我们要知道缓存的目的是什么？

使用缓存可以有效的减少服务器的请求次数，这一特性主要用于缓存静态资源，对于长期不会改变的服务器静态资源，启用缓存则无需从服务器二次下载。

缓存分为两种类型，分为 **强制缓存** 与 **协商缓存**：

对于强制缓存，请求数据会默认存放于磁盘上，每次只要请求相同的 url，就会启用本地的缓存而不向服务器建立连接。

然而协商缓存是通过与服务器对比请求资源的信息来判断缓存资源是否过期，如果过期就重新获取资源，没有过期就启用本地的缓存资源而不再向服务器下载该资源。判断资源是否过期的依据方式由多种，比如可以通过判断服务器上静态资源的更新时间与本地缓存资源的更新时间是否一致来判定，还可以设置一个固定的过期时间，等等。

如果不使用缓存，那么浏览器每发起一个请求就会从服务器重新获取一遍资源，对于大多数服务器来说，是不会启用这一方式的，只有用户使用 `ctrl + F5` 刷新页面时才会重新请求资源。


# 1. Cache-control 头

在 Http/1.1 Header 的 `Cache-control` 字段可以存放缓存相关的信息，以 Express 框架为例，我们可以使用 `req.set` 来设置 Http Header，从而自定义请求缓存：

```js
app.get("/resource", function(req, res) {
  res.set({ "Cache-Control": "no-store" });
  res.send({ name: "huahua", age: 18 });
});
```

通常可以进行如下几项设置：

## 1.1 禁止缓存

缓存中不得存储任何关于客户端请求和服务端响应的内容。每次由客户端发起的请求都会下载完整的响应内容。

```html
Cache-Control: no-store
```

启用 no-store 后每次请求状态码都是 200 ，意味着每次请求都是从服务器重新获取的。

![](https://i.loli.net/2019/11/27/t8GiJYRX9anbdrC.png)

## 1.2 强制确认缓存

如下头部定义，此方式下，每次有请求发出时，缓存会将此请求发到服务器（译者注：该请求应该会带有与本地缓存相关的验证字段），服务器端会验证请求中所描述的缓存是否过期，若未过期，服务器会向客户端返回一个 304 状态码表示资源未被转移，客户端可以使用本地缓存。

```html
Cache-Control: no-cache
```

![20191127003501.png](https://i.loli.net/2019/11/27/jicZeKFHkGhCYaJ.png)

## 1.3 私有缓存和公共缓存

"public" 指令表示该响应可以被任何中间人（译者注：比如中间代理、CDN等）缓存。若指定了"public"，则一些通常不被中间人缓存的页面（译者注：因为默认是private）（比如 带有HTTP验证信息（帐号密码）的页面 或 某些特定状态码的页面），将会被其缓存。

而 "private" 则表示该响应是专用于某单个用户的，中间人不能缓存此响应，该响应只能应用于浏览器私有缓存中。

```html
Cache-Control: private
Cache-Control: public
```

## 1.4 缓存过期机制

过期机制中，最重要的指令是 "`max-age=<seconds>`"，表示资源能够被缓存（保持新鲜）的最大时间。相对[Expires](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Headers/Expires)而言，max\-age是距离请求发起的时间的秒数。针对应用中那些不会改变的文件，通常可以手动设置一定的时长以保证缓存有效，例如图片、css、js等静态资源。

```html
Cache-Control: max-age=31536000
```

启用 `max-age` 缓存时，浏览器会一直读取本地资源而不向服务器发起请求：

![](https://i.loli.net/2019/11/27/VjtNYor2aZ7GwDn.png)

## 1.5 缓存验证确认

当使用了 "`must-revalidate`" 指令，那就意味着缓存在考虑使用一个陈旧的资源时，必须先验证它的状态，已过期的缓存将不被使用。详情看下文关于[缓存校验](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Caching_FAQ#Cache_validation)的内容。

```html
Cache-Control: must-revalidate
```