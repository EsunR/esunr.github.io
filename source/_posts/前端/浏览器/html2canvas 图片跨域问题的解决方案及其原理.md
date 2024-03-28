---
title: html2canvas 图片跨域问题的解决方案及其原理
tags:
  - HTML2Canvas
  - JavaScript
  - 跨域
categories:
  - 前端
  - 浏览器
date: 2024-03-28 16:49:12
---
# 1. 前言

html2canvas 是一个用于将 DOM 结构转为 canvas 对象的一个库，利用这个库就可以实现对页面的某一部分进行截图这样的功能。

但是由于其工作方式是将 DOM 结构进行解析后渲染在一个离屏 canvas 上，因此会受到一些限制。最常见的就是跨域资源无法被正常渲染，其根本原因是 canvas 调用跨域资源时受到 CORS 的保护，为了避免出现跨域资源的问题通常的解决方案是：

1. 将 html2canvas 的 `useCORS` 设置为 `true`；
2. 受访问的服务器必须支持 CORS，也就是以跨域方式获取资源时要返回对应的跨域头；
3. 为 img 标签添加 `crossorigin="anonymous"` 属性；

但是如果不搞清楚做的每一个行为具体做了什么事情，会发生什么，那么还是会出现各种各样的问题。

# 2. html2canvas 的 allowTaint 与 useCORS

解决方案的第一条『将 html2canvas 的 `useCORS` 设置为 `true`』，表示允许 canvas 中加载使用 CORS 加载跨域资源，那么 `useCORS` 具体做了什么事情？同时 `allowTaint` 选项也是允许画布被污染（也就是允许加载跨域资源），其与 `useCORS` 的开关又有什么关系？本章节主要对这两个问题进行讨论。

### 开启 allowTaint 时具体发生了什么

我们先谈 `allowTaint`，这一选项表示是否允许画布被污染（也就是是否允许在画布中加载跨域资源），可能很多人都尝试开启 `allowTaint` 来加载跨域图片，但却只会得到一个报错，让我们来看看具体发生了什么。

`allowTaint` 默认为 `false` 时，html2canvas 遇到跨域资源（如跨域图片、跨域画布）时会直接不将此元素绘制到画布上，避免 canvas 在调用 `toDataURL` 这类操作画布的 API 时报错，比如出现 `Tainted canvases may not be exported（受污染的画布不得导出）` 的错误。

反之，`alowTaint` 设置为 `true` 后，html2canvas 便会跳过检查跨域资源的这一过程，但如果画布确实被污染，调用 `toDataURL` 等这类操作画布的 API 时就会报错，并且 html2canvas 的 Promise 会走到 catch 阶段。

需要注意的是，对于图片资源只有在 `allowTaint` 设置为 `false` ，且没有使用 `useCORS` 或者 `proxy` 时，才会不将其绘制到画布上，具体的判断代码如下：

> 这也就是 `allowTaint` 和 `useCORS` 的关系了

```js
private async loadImage(key: string) {
	const isSameOrigin = CacheStorage.isSameOrigin(key);
	const useCORS =
		!isInlineImage(key) && this._options.useCORS === true && FEATURES.SUPPORT_CORS_IMAGES && !isSameOrigin;
	const useProxy =
		!isInlineImage(key) &&
		!isSameOrigin &&
		!isBlobImage(key) &&
		typeof this._options.proxy === 'string' &&
		FEATURES.SUPPORT_CORS_XHR &&
		!useCORS;
	if (
		!isSameOrigin &&
		this._options.allowTaint === false &&
		!isInlineImage(key) &&
		!isBlobImage(key) &&
		!useProxy &&
		!useCORS
	) {
		return;
	}
	// ... ...
}
```

### 开启 useCORS 时具体发生了什么

`useCORS` 表示是否尝试使用 CORS 从服务器加载图像，默认为 `false`。当设置为 `true` 时，html2canvas 将跨域图片绘制到 canvas 上时，会为其添加 `crossorigin` 属性：

```js
// html2canvas/src/core/cache-storage.ts
if (isInlineBase64Image(src) || useCORS) {
	img.crossOrigin = 'anonymous';
}
img.src = src;
```

这样请求的图片就会尝试从服务端获取跨域头，确认安全后，图片就正常渲染在画布上。关于具体的图片请求，与 img 标签设置了 `crossorigin="anonymous"` 属性后发起的请求是一致的，具体看后文。

### allowTaint 和 useCORS 设置后的具体表现

| allowTaint | useCORS | 存在跨域资源时调用 `toDataURL` 时的表现                                  |
| ---------- | ------- | ----------------------------------------------------------- |
| false      | false   | 控制台不会报错，但是输出的图像上跨域图片的位置为空白                                  |
| true       | false   | 控制台会报画布被污染的错误，html2canvas Promise 会走到 catch                 |
| true       | true    | 将图片的 crossorigin 设置为 anonymous 后，如果服务器允许跨域，则图片正常被渲染         |
| false      | true    | 当 `allowTaint` 为 `false` 时，但是开启了 `useCORS`,也会加载跨域图片，表现与上面一致 |

# 3. 受访问的服务器必须支持 CORS

如果请求的资源不支持返回跨域头，那么无论 html2canvas 如何配置，画布上都无法渲染出图片，控制台也会输出 CORS 的错误。

以百度云的对象存储 BOS 为例，创建 bucket 后可以在『配置管理』的『跨域访问CORS配置』中对跨域头进行配置：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/2bcec13c6f822e1eca9c7c4b448d578f.png)

此外如果启用了 CDN，也需要检查 『CDN 详情』- 『访问控制』-『跨域访问配置』中是否也允许了跨域：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202403271959966.png)

配置了跨域访问后，如果能够发起一个跨域请求，那么响应头中应该存在 CORS 的相关字段：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202403272002517.png)

# 4. 为 img 标签添加  crossorigin 属性

在解决方案的第3条『为 img 标签添加 `crossorigin="anonymous"` 属性』，那么接下来我们就来解释以下这个行为发生了什么，以及为什么要这么做。

### corssorigin="anonymous" 做了什么

当我们不添加这个属性时，发送的图片请求为：

```sh
curl 'https://esunr-webapp.cdn.bcebos.com/express-vue-template/playground/mountain.webp?freshKey=1711520456453' \
  -H 'accept: image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8' \
  -H 'accept-language: zh-CN,zh;q=0.9' \
  -H 'referer: http://172.24.136.200:5173/' \
  -H 'sec-ch-ua: "Google Chrome";v="123", "Not:A-Brand";v="8", "Chromium";v="123"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "macOS"' \
  -H 'sec-fetch-dest: image' \
  -H 'sec-fetch-mode: no-cors' \
  -H 'sec-fetch-site: cross-site' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36'
```

添加了这个属性后发送的图片请求为：

```sh
curl 'https://esunr-webapp.cdn.bcebos.com/express-vue-template/playground/mountain.webp?freshKey=1711520795407' \
  -H 'accept: image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8' \
  -H 'accept-language: zh-CN,zh;q=0.9' \
  -H 'origin: http://172.24.136.200:5173' \
  -H 'referer: http://172.24.136.200:5173/' \
  -H 'sec-ch-ua: "Google Chrome";v="123", "Not:A-Brand";v="8", "Chromium";v="123"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "macOS"' \
  -H 'sec-fetch-dest: image' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-site: cross-site' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36'
```

将请求进行 Diff：

```diff
+ 'origin: http://172.24.136.200:5173'
- 'sec-fetch-mode: no-cors'
+ 'sec-fetch-mode: cors'
```

发现添加 `crossorigin="anonymous"` 属性后会添加一个 `origin` 与 `sec-fetch-mode` 的请求头，来告诉服务端获取的是一个跨域资源，当 BOS 接收到这个请求头后，会将响应的 `Access-Control-Allow-Origin` 字段设置为与 `origin` 同值。换句话说，`origin` 字段决定了 BOS 返回资源的 `Access-Control-Allow-Origin` 字段的值，**如果请求头中没有 `origin` 字段，BOS 会返回一个错误的、被 CDN 缓存的，或者没有 `Access-Control-Allow-Origin` 响应头的响应**。我们也都应知道，`Access-Control-Allow-Origin` 只有匹配当前域时，CORS 策略才会通过，否则跨域资源就会加载失败。

### 为什么要设置 corssorigin="anonymous"

那接下来我们来解释以下为什么在 img 标签中添加这个属性，其与浏览器的本地缓存是相关的。

假设我们没有设置这个属性，那么浏览器发起图片请求时，返回的图片是一个不带 CORS 相关响应头的资源，浏览器收到这个图片请求后便会将这个资源缓存在本地。当我们调用 html2canvas 时，其会加载相同的资源，那么再加载这张跨域图片后便是从浏览器缓存中取了这个没有 CORS 相关响应头的资源，那这就会导致将图片加载在 Canvas 上时出现 CORS 错误，如下：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202403272026051.png)

浏览器整体的请求流程图如下：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202403272040393.png)

当为 img 标签添加了 `crossorigin="anonymous"` 属性后，浏览器在加载 HTML 中的图片时便会去请求一个携带了 CORS 相关响应头的图片，那么浏览器缓存的图片资源也就是带了跨域头的。那么后面调用 html2canvas 在离屏 canvas 中加载图片时，获取的缓存图片就是符合规格的了，那么就不会出现 CORS 错误了。流程图如下：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202403272059883.png)

# 5. 来自其他页面的缓存

在上一章节中，我们解释了设置 `crossorigin="anonymous"` 是为了防止当前页面缓存一个没有 CORS 相关响应头的图片资源，在大多数情况下已经可以正常工作了。但当我们在其他页面页面或域加载了相同的图片资源时，他们所创建的缓存还是会影响到 html2canvas 的图片渲染的，这点需要特别注意。

### 来自同站点的图片缓存

拿具体的示例来说，假如同一张图片出现在了当前网站的其他页面，但是使用该张图片的 img 标签未添加 `corssorigin` 属性，那么浏览器又会缓存一个没有 CORS 相关响应头的图片资源，导致 html2canvas 的图片渲染失败，同时网站内其他使用了相同图片并为 img 添加了 `corssorigin`  属性位置的图片也会加载失败，流程图如下：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202403281410292.png)

### 来自同域的缓存

此外还有一种情况需要额外注意，在浏览器缓存中，**相同一级域名下的图片缓存，在子域名之间是会互相复用的**，比如在域名 `local.baidu.com` 访问了图片 `mountain.webp`，那么在域名 `local2.baidu.com` 下访问相同的图片 `mountain.webp` 时，就会去获取第一次访问 `local.baidu.com` 时创建的缓存，即使两个域名的 img 标签都添加了 `corssorigin` 属性，但拿到的缓存图片响应头中的 `Access-Control-Allow-Origin` 是错误的，就仍然会造成 CORS 错误，流程图如下：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202403281653329.png)

### 解决方案

**方案一：**

如果想要避免同站点缓存一张没有 CORS 响应头的资源，那么就要为所有 html2canvas 调用到的图片，在其同站点任何位置的 img 标签都添加上 `corssorigin` 属性，那这样自然就不会缓存错误的图片资源了，但这其实也并不算很严谨，因为你不知道这种行为什么时候就会被破坏。

**方案二：**

如果确实会遇到来自同域的缓存，方案一就不适用了，我们可以尝试是否能让服务端返回的图片资源，在遇到跨域请求时始终携带 `Access-Control-Allow-Origin: *` 的响应头，这样即使使用了其他域的缓存资源，由于其缓存的 `Access-Control-Allow-Origin` 值为通配符 `*`，那么在当前站点仍符合 CORS 策略，可以被正常加载。

以 BOS 为示例，在『配置管理』-『跨域访问CORS配置』中，默认的值为 `https://* http://*`，这代表 BOS 如果遇到跨域请求，会将 `Access-Control-Allow-Origin` 动态设置为请求头 `origin` 字段的值。我们需要将其改为 `*` 后保存，这样 BOS 在收到跨域请求时就不会进行判断，而是恒返回一个 `*`。

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202403281545753.png)

配置完成后请求图片：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202403281550019.png)

但是这样我们仍要保证站点内所有 html2canvas 调用的图片都得是跨域请求（也就是所有 img 标签都得有 `crossorigin` 属性），但是如果使用了 CDN 便可避免这一问题。CDN 支持自定义响应头，那么我们只要在 CDN 上添加 `Access-Control-Allow-Origin: *` 的响应头即可无论是否是跨域请求，都会携带该响应头，因此浏览器中缓存的资源始终都是合法的跨域资源，那么接下来 html2canvas 的操作便没有任何问题了，具体设置入口在 CDN 管理面板中，设置方式如下：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202403281553149.png)

**方案三：**

如果我们在已有的项目中实在不好去变动 Bucket 的设置，那我们为了保证 html2canvas 渲染不出错，就只能强行让 html2canvas 获取的图片不使用缓存，也就是每次访问的都是一张新图片。为了避免使用缓存，可以在图片的 src 后面追加一个时间戳作为 query，如：

```html
<img :src="`https://xxx/mountain.webp?timestamp=${new Date().valueOf()}`" />
```

但这样的话，浏览器的图片缓存机制就会失效，并且如果使用了 CDN，每次请求都会触发回源，出于性能表现上是不太推荐这样做的。

**也许还有一种解决方案？**

html2canvas 上还存在一个配置项 `onclone`，表示在克隆 DOM 进行渲染时调用的函数，其本质是用于在不修改原始 DOM 的状态下对在 Canvas 上渲染的内容进行修改。那么我们就可以尝试是否能在正常的页面上请求不跨域的图片，然后在 `onclone` 函数中请求跨域图片，同时修改图片的 src 为其后缀一个时间戳，让其渲染在 Canvas 上时不使用缓存，代码如下：

```js
html2canvas(renderAreaRef.value, {
  allowTaint: html2canvasOptions.allowTaint,
  useCORS: html2canvasOptions.useCORS,
  onclone: (doc) => {
    const images = doc.querySelectorAll('img');
    images.forEach((img) => {
      img.setAttribute('crossorigin', 'anonymous');
      const imgSrc = img.getAttribute('src');
      img.setAttribute('src', `${imgSrc}?timestamp=${new Date().valueOf()}`);
    });
  },
})
  .then((canvas) => {
    const img = canvas.toDataURL('image/png');
    // TODO: 导出图片
  })
  .catch((e) => {
    ElMessage.error('生成图片失败，查看控制台错误');
    console.error(e);
  });
```

但是经过尝试后，Canvas 上会绘制出来一张空白图片，因此这个方案可能暂时不适用：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202403281647507.png)

但是如果使用 css 属性 `backgroundImage` 来加载图片却可以使用该方法：

```js
html2canvas(renderAreaRef.value, {
  allowTaint: html2canvasOptions.allowTaint,
  useCORS: html2canvasOptions.useCORS,
  onclone: (doc) => {
    const images = doc.querySelectorAll('.need-print-img');
    images.forEach((img) => {
      const backgroundImageUrl = (
        img as HTMLDivElement
      ).style.backgroundImage.replace(/url\((['"])?(.*?)\1\)/gi, '$2');
      const newImageUrl = `${backgroundImageUrl}&timestamp=${new Date().valueOf()}`;

      // 使用跨域请求预加载 image 图片
      const _img = new Image();
      _img.crossOrigin = 'anonymous';
      _img.src = newImageUrl;

      (img as HTMLDivElement).style.backgroundImage = `url(${_img.src})`;
    });
  },
})
  .then((canvas) => {
    const img = canvas.toDataURL('image/png');
    // TODO: 导出图片
  })
  .catch((e) => {
    ElMessage.error('生成图片失败，查看控制台错误');
    console.error(e);
  });
```