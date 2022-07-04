---
title: http与浏览器的缓存机制
tags:
  - 网络原理
categories:
  - 前端
  - 浏览器
date: 2019-11-26 23:50:07
---

# 缓存基础

首先我们要知道缓存的目的是什么？

使用缓存可以有效的减少服务器的请求次数，这一特性主要用于缓存静态资源，对于长期不会改变的服务器静态资源，启用缓存则无需从服务器二次下载。

缓存分为两种类型，分为 **强制缓存** 与 **协商缓存**：

对于强制缓存，浏览器会根据上次请求获取的 `Cache-Controller` 或 `Expires(http 1.0 规范)` 来判断截止当前请求发起时，本地的缓存资源是否过期，如果本地缓存的资源未过期，就会启用本地的缓存而不向服务器建立连接，此时虽然没有建立服务器端的连接，但仍会收到 200 的状态码，但是会被标记为 `from cache`。

然而协商缓存是通过上次请求的 `Etag` 或 `Last-Modified` 与服务器对比请求资源的信息来判断缓存资源是否过期，如果过期就重新获取资源，没有过期就启用本地的缓存资源而不再向服务器下载该资源，此时会收到 304 的状态码，标记为 `not modified`。协商缓存要比强缓存流程要多一些，具体过程入下：

![](https://i.loli.net/2021/07/20/e1cLN3xQdi6aDh4.png)

如果不使用缓存，那么浏览器每发起一个请求就会从服务器重新获取一遍资源，对于大多数服务器来说，是不会启用这一方式的，只有用户使用 `ctrl + F5` 刷新页面时才会重新请求资源。


# 1. Cache-control

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

# 2. ETag

ETag 是在响应头中存放的一个字段，用于校验服务器资源是否过期，从而判断是否启用缓存，对于访问服务器的静态资源来说，ETag 可以表示为静态文件的 Hash。

如果给定URL中的资源更改，则一定要生成新的 Etag 值。 因此 Etag 类似于指纹，也可能被某些服务器用于跟踪。 比较 Etag 能快速确定此资源是否变化，但也可能被跟踪服务器永久存留。

ETag 通常用于实现两种功能：

1. 检测资源是否变更，如未变更，则采用缓存资源
2. 防止资源请求过程中发生“空中碰撞”

## 2.1 检测资源是否变更

通常用户首次发起请求时，服务器端返回的响应报文的响应头部中会包含 ETag 的信息，如：

![](https://i.loli.net/2021/06/21/ScHltx59j6kAXyn.png)

这一信息将被客户端所记录，并且在后续的请求中会在请求报文的头部添加一个 `if-none-match` 的字段，该请求发送到服务器端时，会检测与服务器端 ETag 是否匹配，如果匹配到，说明资源未发生变更，此时会返回 304 状态码，客户端则会读取缓存资源，如：

![](https://i.loli.net/2021/06/21/4YDweO9yNboTFQ3.png)

## 2.2 防止 “空中碰撞”

在`ETag`和 [`If-Match`](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Headers/If-Match) 头部的帮助下，您可以检测到"空中碰撞"的编辑冲突。

例如，当编辑MDN时，当前的wiki内容被散列，并在响应中放入`Etag`：

```
ETag: "33a64df551425fcc55e4d42a148795d9f25f89d4
```

将更改保存到Wiki页面（发布数据）时，[`POST`](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Methods/POST)请求将包含有ETag值的[`If-Match`](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Headers/If-Match)头来检查是否为最新版本。

```
If-Match: "33a64df551425fcc55e4d42a148795d9f25f89d4"
```

如果哈希值不匹配，则意味着文档已经被编辑，抛出[`412`](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Status/412)前提条件失败错误。

# 3. Last-Modify

The **`Last-Modified`**  是一个响应首部，其中包含源头服务器认定的资源做出修改的日期及时间。 它通常被用作一个验证器来判断接收到的或者存储的资源是否彼此一致。由于精确度比  [`ETag`](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Headers/ETag) 要低，所以这是一个备用机制。包含有  [`If-Modified-Since`](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Headers/If-Modified-Since) 或 [`If-Unmodified-Since`](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Headers/If-Unmodified-Since) 首部的条件请求会使用这个字段。

