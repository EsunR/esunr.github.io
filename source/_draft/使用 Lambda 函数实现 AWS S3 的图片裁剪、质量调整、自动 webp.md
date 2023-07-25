> 本文章只是一个引子，如果你想参考具体的代码实现以及详细的部署流程，欢迎直接使用我的开源项目：[s3-image-handler](https://github.com/EsunR/s3-image-handler)

# 1. 前言

不同于国内的很多对象存储服务，AWS S3 并不提供图像处理的服务，需要用户使用 Lambda 函数或者 EC2 搭建图片裁剪服务，这就使用用户有比较高的使用门槛了，但是相当于国内云服务厂商提供的黑盒图像处理服务，AWS Lambda 也有着透明、高兼容度、高可编程性的优势。

首先我们要明确一下最终的实现需求，需要达到以下的功能：

- 请求携带图像处理参数访问图片后返回相应的处理好的图片；
- 处理过的图片要存储到 S3 上，防止重复的图片处理请求；
- Lambda 函数要部署到全球边缘节点，而不只是一个固定的地区，以加快用户的调用速度；
- 支持 CloudFront 缓存，加快用户访问；
- 需要支持自动转换格式，如果用户的浏览器支持 webp 则自动请求 webp 资源

那么接下来我们将逐步实现它。

# 2. 先来个简单的架构吧

我们先假设搭建了一个图片存储服务，那么当用户每次发起请求时，请求都会经过一个 `Image Handler` 服务（我们暂不考虑其具体实现），其相当于一个中间人的角色，如果访问的图片存在于 S3 上，那么 `Image Handler` 就将图片原封不动的返回给用户。

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202307251653285.png)

但是如果我们为图片添加一些格式转换的参数，比如说请求 `image.jpg__op__format,f_webp` 代表获取 `image.jpg` 的 webp 格式的图片，那么经过 `Image Handler` 这个中间服务时候就会执行如下流程：

1. Image Handler 尝试获取 `image.jpg__op__format,f_webp` 文件，结果文件不存在；
2. Image Handler 去除格式转换参数，请求 `image.jpg` 文件，成功获取文件；
3. Image Handler 解析格式转换参数，并调用图像处理工具对图片进行格式转换；
4. Image Handler 将转换好格式的图片上传至 S3；
5. Image Handler 重定向用户请求，让用户重新获取 S3 资源

整体流程图如下：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202307251722922.png)

那么接下来我们就由简入繁，尝试实现以下这套架构。

# 3. 使用 API Gateway + Lambda 实现 ImageHandler

### 初始架构

上节我们文中提到的 `Image Hanlder` 就可以使用 Lambda 函数来实现，我们可以加上一个 API GateWay 服务来用于触发 Lambda 函数，那么架构图就会变为：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202307251811317.png)

这个与我们上面的架构图差别不大，只是将 `Image Handler` 由 Lambda 和 API Gateway 相结合而实现。其中，API Gateway 只作为 Lambda 函数的触发器，用户请求图片时就直接请求 API Gateway 的访问 url，并将访问文件的路径作为 path 参数拼接入 url，如 `api-gateway?path=image.jpg__op__format,f_webp`，然后 Lambda 函数收到会从 API Gateway 发来的事件，并提取 url query 中的文件路径，执行获取图像、处理图像、返回图像等上节我们提到的操作。

### 优化架构

但是我们会发现，如果用户直接请求 API Gateway 的话，那么每次请求都会触发 Lambda 函数的执行，而 Lambda 函数检查文件是否存在的这一行为也会消耗大量的时间。

因此我们需要优化一下架构：首先让用户请求 S3，如果 S3 文件不存在就使用 307 临时重定向，让用户访问 API Getway 的 url，然后再触发 Lambda 函数。此时可以确定的是用户访问的是不存在于 S3 的图片，因此 Lambda 函数无需检查图片是否存在，直接从 S3 中获取原始图片并处理，处理完成后使用 301 永久重定向让用户重新从 S3 获取由 Lambda 处理好的图片，下次请求用户遍也无需经过 Lambda 函数，这样大大提升了用户的访问效率。修改后的架构图如下：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202307251821604.png)

### 架构实现

上面的架构在 Github 上有完整的实现参考：[s3-resizer](https://github.com/sagidM/s3-resizer/tree/master)，与上面描述唯一不一样的为图像处理参数的处理，该函数只专注于图片裁剪，想要其他的功能需要自己实现。

需要值得注意的一点是，S3 如果查找不到图片返回 307 重定向的这个行为，S3 默认是无法实现的，需要开启 S3 的 **静态网站托管服务**，这样就可以改写资源 404 时的行为，让 S3 重定向到 API Gateway，具体
的配置流程可以在 [s3-resizer](https://github.com/sagidM/s3-resizer/tree/master) 项目的 README 中查看。

### 架构缺陷

其实这个架构是有明显的缺陷的，总结为以下几点：

- 开启静态网站托管后，AWS 不支持 https 访问，要想开启 https 需要自己的域名，[参考](https://github.com/sagidM/s3-resizer/issues/7)；
- 过多的重定向，如果某个图片不存在，则需要三次重定向才能获取到图片，这个过程在高并发的资源请求下简直是灾难；
- CloudFront 比较麻烦；
- API Gateway 的请求会被用户用户抓取到，那么用户可以一直重复请求；
- Lambda 函数和 API Getway 只能部署在固定的地区，如果用户请求来自其他地区，函数响应速度将会收到影响；
-  这个架构无法实现自动 webp。

 这个架构如果可以接入 CloudFront 已经可以应对一些简单的项目了，但是多次重定向、Lambda 函数无法全球化的问题确实是比较致命的，因此我们接下来将探讨另外一种实现方案，可以把上面的问题都解决掉。

# 3. 使用 Lambda@Edge 实现 ImageHandler

