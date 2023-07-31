---
categories:
  - 云原生
---
> 本文章只是讲实现方案，并不会涉及具体的代码上线，如果你想参考代码以及详细的部署流程，可以参考该项目：[s3-image-handler](https://github.com/EsunR/s3-image-handler)

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
	1. 此时，S3 会同时存在 `image.jpg` 和 `image.jpg__op__format,f_webp` 两个文件。
5. Image Handler 重定向用户请求，让用户重新获取 S3 资源。

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
- CloudFront 加速比较麻烦；
- Lambda 函数和 API Getway 只能部署在固定的地区，如果用户请求来自其他地区，函数响应速度将会收到影响；
-  这个架构无法实现自动 webp。

 如果不需要优化多区域访问速度的话，这个架构已经可以应对一些简单的项目了，但是多次重定向、Lambda 函数无法全球化的问题确实是比较致命的，因此我们接下来将探讨另外一种实现方案，可以把上面的问题都解决掉。

# 3. 使用 Lambda@Edge 实现 ImageHandler

### Lambda@Edge 简介

Lambda@Edge 是 AWS 的边缘计算服务，不同于普通的 Lambda 函数：普通的 Lambda 函数只能部署在单个区域的节点上，然后用户通过设置的触发器（如 API Gateway）来触发该函数；而 Lambda@Edge 可以借助 CloudFront 部署在全球的边缘节点上，当用户访问某个与其物理位置最接近的 CloudFront 分配时，就会触发部署在其上面的 Lambda@Edge 函数。

由于 Lambda@Edge 完全依托于 CloudFront，其触发流程也是围绕着用户请求某个 CloudFront 节点的生命周期，具体如下：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202307311108474.png)

- 当用户访问到某个 CloudFront 分配且在 CloudFront 检查缓存之前，首先会触发 viewer request；
- 当 CloudFront 没有发现缓存资源时候，按照回源规则向上访问时（如当 S3 上存放的图片没有被 CloudFront 缓存，那么就会回源访问到 S3），就会触发 origin request；
- 当 CloudFront 收到来自源的响应之后、在缓存行为发生之前，会触发 origin response；
- 当 CloudFront 将用户请求的资源返回前，会触发 viewer response。

Lambda@Edge 可以部署在以上四个 CloudFront 资源请求的时间点，**并且可以在 request 阶段修改用户的请求，在 response 阶段修改服务器返回的响应**。

但是 Lambda@Edge 是有部署条件的：

- **只有弗吉尼亚北部（us-east-1）上的 Lambda 函数才能部署到 CloudFront 上**，成为 Lambda@Edge 函数，其他地区的函数触发器都不包含 CloudFront；
- viewer request 和 viewer response 的资源配额较小，编程时需要额外注意，响应时长不得超过 5s，内存分配不得超过 128M，Lambda 及其依赖包大小不得超过 1M；
- 如果需要篡改响应，那么只能返回给客户端纯文本或者 base64 编码；
- 由于函数经过 CloudFront，到 OriginResponse 后就会被移出掉客户端的请求头字段，如果需要透传，则需要手动在 CloudFront 的 `行为` 面板中单独配置 `源请求策略`；
- 更多功能限制可以查看 [这里](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/edge-functions-restrictions.html)；
- 更多配额限制可以查看 [这里](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cloudfront-limits.html)。

## 使用 Lambda@Edge 实现 ImageHandler

首先，我们要将 S3 接入 CloudFront，这样才能进一步接入 Lambda@Edge，关于具体如何接入，可以参考 [这篇文章](https://blog.esunr.xyz/2023/07/cd2440f9b860.html)。

将 S3 接入 CloudFront 之后，我们再来看一下 CloudFront 的工作机制，与所有的 CDN 服务一样，当 CloudFront 没有缓存时，就会触发回源，如果有缓存且缓存没有失效，就不会触发回源，而是直接从服务器节点获取资源：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202307311403801.png)

那么 Lambda@Edge 函数的四个触发时间点，就分布在下图所示的四个阶段：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202307311433055.png)

以上的流程图中演示的是用户请求了一张 S3 存在的图片，那么假如用户请求了一张携带了图片处理参数的图片（假设携带了参数的图片不存在于 S3 上），当请求会回源到 S3，然后触发 403 Forbidden（PS：S3 没有 404 的状态码，无权限和文件不存在都是 403），我们所要做的就是 **修改这次回源响应** ，让回源返回的是一张处理好的图片，而不是 403 状态码。

经过上面的流程分析，很容易发现最合适操作的位置就是 `origin response` 阶段，因为在这一阶段可以直接获取到 S3 的回源结果：如果是一个 200 的状态码，就说明用户请求的是原始图片，或者带参数的图片已经存在于 S3 中；反之，如果是一个 403 状态码，就说明图片不存在，此时 Lambda 函数就开始进行获取原图、处理图片、上传图片、返回响应的这一系列行为。

以用户请求 `image.jpg__op__format,f_webp` 这一携带了图片处理参数的请求为例，经历了如下流程：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202307311512282.png)
如果用户请求了一个原始图片不存在，但是携带了图片操作参数的图片（如 `error.jpg__op__format,f_webp`），`origin response` 阶段部署的 Lambda 函数依旧会工作，但由于 Lambda 函数并不确定原始图片是否存在，仍然会尝试二次向 S3 请求原始图片来确认，如果原始图片确实不存在，那么 Lambda 函数则仍返回原响应（403），工作流程如下：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202307311531640.png)

## 添加自动 webp 的功能

webp 格式在提升 Web 图片传输效率上有很大的优势，能将图片进一步压缩，不仅节省 S3 的存储空间以及 CloudFront 的流量消耗，更能页面更快的展现给用户，在上面的示例中，我们请求 `image.jpg__op__format,f_webp` 的目的就是为了指定获取 webp 的图片而不是原图。

但是对于 webp 的支持上，Safria 浏览器极其拉胯，直到 2022 年的 Safria 16 才 [完全支持](https://caniuse.com/webp)，为了某一小撮浏览器的兼容性，我们并不能大放手脚的全站使用 webp。从前端开发来讲，虽然完全可以从前端写一个判断函数来判断用户浏览器是否兼容 webp 而编程式的来获取不同格式的图片，但这样做并不是完美的，比如 SSR 场景来说，在客户端和服务端都要写两套判断代码，简直徒增工作量。

那么最优雅的解决方案还是从我们刚才写的 Lambda 函数入手，新增一个 `f_auto` 参数，比如当用户请求 `image.jpg__op__format,f_auto` 时，通过用户的 request header 的 accept 字段来判断用户的浏览器是否支持 webp，如果支持则返回格式为 webp 的图片，否则返回原图。设想很美好，但是当我们按照这个思路去完善 origin response 阶段部署的 Lambda 函数时却很容易发现走不通，会出现两个致命的问题：

1. 从 origin response 阶段的 Lambda 函数事件中，并不获取到 accept 请求头，因为该请求是从 CloudFront 转发过来的，转发过程中 CloudFront 会移除掉部分客户端请求头。
2. 就算我们在 CloudFront 中进行了配置，允许 accept 透传到 origin response 阶段，如果判断出来用户支持 webp，那么就会生成一张名为 `image.jpg__op__format,f_auto` 格式为 webp 的图片上传到 S3。但当下一个用户浏览器不支持 webp 时，请求的仍为 `image.jpg__op__format,f_auto` 就会获取到由上个用户生成的 webp 格式的图片。也就是说，在 origin response 阶段写的自动格式判断逻辑只能满足首个用户的浏览器需求，后续的用户请求过来的图片都是首个用户触发生成的图片。

因此，我们不可能通过完善 origin response 的 Lambda 函数来实现自动 webp 的功能。但是我们还可以考虑部署于其他位置的 Lambda@Edge 函数来实现这一功能，还记得 Lambda@Edge 的能力吗？不仅可以修改回源响应，**更能在 request  阶段修改用户请求**。假如我们在 request 阶段判断用户的浏览器是否支持 webp，如果支持的话就将用户请求改为 `image.jpg__op__format,f_webp`，反之则将用户请求改为 `image.jpg` 使用户请求原图，这样后续 origin response 处部署的 Lambda 函数就仍只需要关注图片处理参数即可。

但是可以修改用户请求的时间点有两处，一处是 viewer request，另一处则是 origin request：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202307311556050.png)

具体应该使用哪个呢？答案是 viewer request。

因为 origin request 只会在 CloudFront 不存在缓存进行回源查找时才会触发，假如自动 webp 的逻辑放在此处，一旦某个使用了支持 webp 格式浏览器的用户访问了携带了 `f_auto` 参数的图片，经过图片处理函数的操作后 CloudFront 就会缓存上 webp 格式的图片；后续假如来了一个使用不支持 webp 格式浏览器的用户访问了该图片，因为存在缓存，所以回源过程并不会触发， origin request 自然也不会触发，该用户只会获取到 CloudFront 上缓存的 webp 格式的图片。

但是 viewer request 却不同，因为其位于用户访问 CloudFront 的阶段上，因此不论 CloudFront 是否有目标图片的缓存，viewer request 始终会触发，那么我们只需要在 viewer request 阶段部署一个 Lambda 函数来根据用户的请求头判断用户使用的浏览器是否支持 webp，根据判断结果修改用户的请求 uri，就可以实现自动 webp 的功能，具体流程如下：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202307311648469.png)

## 架构优化

上面只是演示了最基础的实现方案，虽然已经可以投入使用了，但这个架构还有一定的优化空间，具体如下，可以进行参考：

- 在 origin response 处理完图片后，由于收到限制，只能将返回的图片编码为 base64 返回，浏览器必须等待所有的数据都返回才会渲染图片，而不是像普通图片那样在请求加载时浏览器就已经开始渲染图片。这个对于弱网环境效果尤为明显，因此建议在 origin response 处理后，返回的响应字段里添加 `cache-control: no-cache, no-store, must-revalidate`，这样 CloudFront 上就不会缓存首次请求触发的 base64 图片，而是等待缓存下次请求的正常图片。
- origin response 改写的响应是有大小限制的，base64 编码后的大小不得大于 1.33M。如果转换后的图片大小超过这个限制，可以使用重定向，让服务端重新请求资源，此时请求的就是从 S3 中拿的资源了。
- 在图片处理前，在 Lambda 函数中会去尝试下载原始图片，应该尽量减少这一行为的触发，除了单纯的判断 S3 上并不存在已经处理的图片外，还应该判断用户的请求是否是获取图片的请求、请求是否携带了正确的图片处理参数等。
- S3 无法查找图片和权限不足返回的都是 403 状态码，如果某个路径下的资源不允许普通用户读取，那么图片处理函数中一定要对其进行特殊处理，不能一昧的把 403 作为图片不存在的状态码来处理，否则会造成权限泄露。推荐在使用该架构时，bucket 中所有内容的权限都是统一的。

## 架构缺陷

虽然当前的架构已经满足了我们的需求，但是其还是存在着一些无法避免的缺陷，需要开发者知悉：

- 权限缺陷：需要注意防止越权操作；
- 性能缺陷：图片过大可能出现无响应的状态；
- 无法避免的上传时长等待：图片转换后 Lambda 函数需要等待上传函数执行完成才能返回给客户端响应，将上传操作放进异步线程先返回客户端响应会导致上传行为失败；

# 参考引用

- [Resizing Images with Amazon CloudFront & Lambda@Edge | AWS CDN Blog](https://aws.amazon.com/cn/blogs/networking-and-content-delivery/resizing-images-with-amazon-cloudfront-lambdaedge-aws-cdn-blog/)
- [Get started creating and using Lambda@Edge functions](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-edge-how-it-works.html)
- [Serverless with AWS – Image resize on-the-fly with Lambda and S3](https://dashbird.io/blog/aws-image-resize-with-lambda-and-s3/)
