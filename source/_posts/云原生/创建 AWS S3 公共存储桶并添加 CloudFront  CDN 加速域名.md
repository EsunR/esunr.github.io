---
title: 创建 AWS S3 公共存储桶并添加 CloudFront CDN 加速域名
tags:
  - AWS
  - S3
  - CloudFront
  - CDN
description:
  本文介绍了如何使用AWS CloudFront CDN服务加速S3存储桶中的内容。首先，在AWS S3创建存储桶并设置公共读权限，然后在AWS
  CloudFront创建分配并选择S3存储桶分配的域作为源，即可获得CDN分配的域名用于访问加速内容。本文还介绍了如何使用自定义域名以及如何清理缓存，以便及时更新资源。最终，使用CDN的优势是显著提高了网站或应用程序中的资源加载速度。
categories:
  - 云原生
date: 2023-07-25 14:37:54
---

# 1. 创建 AWS S3 存储桶

进入 [S3 控制台](https://s3.console.aws.amazon.com/s3/home)，点击 `创建存储桶（Bucket）`，地区优先选择用户多的位置，输入桶名称后直接点击确认创建。

此时我们已经可以为创建好的存储桶上传文件了，点击上传的文件对象查看详情，复制对象 URL 到浏览器中：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20230725141918.png)

然后会发现页面 403 Forbidden 的警告，因为我们默认设置的存储桶是没有公共读权限的，截下来需要为创建的 Bucket 设置公共读权限。

# 2. 设置存储桶权限

点击 Bucket 列表中刚才创建的 Bucket，点击进入详情后选择进入权限面板，编辑 `屏蔽公共访问权限（存储桶设置）`，取消选中所有选项并保存更改：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202307251356944.png)

继续停留在权限面板，编辑 `存储桶策略`，并输入以下权限（注意将 `your-bucket-name` 改为你的存储桶名称）：

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::your-bucket-name/*"
        }
    ]
}
```

然后保存，此时，你的存储桶会拥有公共读的权限，Bucket 列表中的访问会出现 `公开` 的警告：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202307251402414.png)

# 3. 创建 CloudFront 分配

然后进入 [CloudFront 控制台](https://us-east-1.console.aws.amazon.com/cloudfront/v3/home)创建一个新的分配，并选择 `源域` 为 S3 刚才创建的 Bucket 所分配的域，名称可随意填写一个备注名，其他使用默认配置即可：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202307251406615.png)

> 点击确认时可能会询问是否添加安全防护，选择不添加即可

进入刚才创建的 CloudFront 分配，查看详细信息中分配的域名，你就可以使用该域名访问刚才创建的 Bucket 的内容了。

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202307251423281.png)

比如，原来使用 S3 分配的域名访问文件的地址为 `https://image.s3.us-west-1.amazonaws.com/avatar.jpeg`，使用 CloudFront 分配的 CDN 加速域名就会变为 `https://xxxxxxxx.cloudfront.net/avatar.jpeg`。

可以看出使用 CloudFront 分配的加速域名与使用 S3 分配的域名有明显的速度差距，并且支持了 http2：

![使用 S3 域名](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202307251427416.png)

![使用 CloudFront 分配域名进行访问](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/20230725142820.png)

# 4. 使用自定义域名

> 由于这里需要域名就不详细描述了，只提供设置方法

如果要使用自己的域名，可以在 CloudFront 分配的详情面板中设置 **备用域名**，设置成功后即可使用自己的域名访问 S3 的文件，并享有 CloudFront 的加速。

# 5. 清理缓存

CloudFront 默认会缓存文件 24 小时，也就是说，如果你 S3 上的某一个已经缓存在 CloudFront 上的 **同名资源** 在 24 小时内有所更新，那么使用 CloudFront 域名访问该资源文件时仍会获取到旧的、被缓存的那一个版本的文件。

最好的解决方案是上传文件时为文件添加哈希后缀，但如果需要手动清理缓存资源则可以进入到 CloudFront 上的 `失效` 面板，创建一个新的失效：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202307251436231.png)

如果想要清理所有缓存内容，规则中输入 `/*` 即可删除所有缓存资源。