---
title: 图片格式转换神器 imagemagick 7 的安装与使用
tags: []
categories:
  - Other
date: 2020-01-06 11:00:45
---

# 1. ImageMagick 简介

ImageMagick 是一个多平台的图片转换工具，在服务器端提供了多语言的插件，可以调用其图片转换能力，大致的图片转换流程如下：

![](http://img.cdn.esunr.xyz/markdown/20200106113214.png)

ImageMagick 同时还提供了 webp 格式图片转换的能力，我们将上传服务器的图片转换为 webp 格式后，图片的大小将会被很大程度的缩减，用户在从服务器端下载图片的时间也会被极大缩小，是一个非常强的优化网站图片加载的手段，以下的测试数据来自凹凸实验室 [webp测试报告](https://aotu.io/notes/2016/06/23/explore-something-of-webp/index.html)：

![JPG和WebP图片大小对比](http://img.cdn.esunr.xyz/markdown/20200106113758.png)

![加载时间对比](http://img.cdn.esunr.xyz/markdown/20200106113848.png)

# 2. 安装前准备

在安装 ImageMagick 7 之前还需要安装各种格式的 lib 库，因为 ImageMagick 图片格式转换能力需要各种图片库作为依赖，如果没有安装这些库就无法使用 ImageMagick 对该图片格式的转换能力，如下的官方文档中对各种格式进行了需求说明，其中标注有 “需要委托库” 就是需要用户下载对应的委托库，才可以开启对该格式的支持：

> 官方文档：http://www.imagemagick.com.cn/formats.html

我们常见的 png、jpeg 格式都需要委托库的支持，同时 webp 格式也需要对应委托库的支持，需要首先下载这些委托库：

```sh
sudo apt-get libwebp-dev libpng-dev libjpeg-dev
```

对于 webp 来说，需要安装的插件要多一些，我们可以选择源码安装最新版本的 webp 开发套件，当然也可以直接使用 apt 指令安装：

```sh
sudo apt-get libwebp-dev webp
```

我们可以通过命令行指令来测试来查看 webp 委托库是否安装成功：

```sh
cwebp -version
> 0.6.1
```

# 3. 源码安装 ImageMagick 7

如果对 webp 格式没有要求，可以直接使用 apt 安装 ImageMagick：

```sh
sudo apt-get install imagemagick
convert -version
```

输出版本可以查看到版本为 6.x。使用 apt 安装的 ImageMagick 甚至可以不用手动安装图片依赖库，但是 ImageMagick 6.x 无法支持 webp 格式（或许支持，但是我没找到开启的方法），我们可以使用指令列出支持的列表，看出其并不支持 webp：

```sh
convert -list format | grep webp
```

为了支持 webp，我们需要按照以下流程手动源码安装 webpm，在这之前我们需要手动卸载之前安装的 `iamgemagick`：

```sh
apt-get apt-get --purge remove iamgemagick
```

确保了完整卸载之后，就可以进行源码安装了（需要 sudo 权限）：

1. 下载源码
   
   ```sh
   cd /usr/source  
   wget https://imagemagick.org/download/ImageMagick.tar.gz
   ```

2. 解压源码

   ```sh
   tar xvzf ImageMagick.tar.gz
   cd ImageMagick-7.0.9
   ```

3. 安装 perl 依赖

   经过测试如果不安装该依赖，安装过程将出错：

   ```sh
   apt-get install libperl-dev
   ```

4. 生成编译文件

   这一步需要进行一个配置，为了防止将 ImageMagick 安装到未知的地方，我们需要手动指定安装位置，同时还需要开启对各种图片格式的支持：

   ```sh
   ./configure --with-modules --enable-shared --with-perl –prefix=/usr/local/imagemagick
   ```

5. 编译安装

   ```sh
   make && make install
   ldconfig /usr/local/lib # 配置动态链接器运行时绑定，如果采用默认位置安装则需要使用这一步让命令行生效
   ```

6. 设置 PATH

   由于我们将源码安装的 ImageMagick 安装到了自定义目录下，所以需要手动连接 bin 文件到 PATH 中：

   ```sh
   sudo vim /etc/profile

   ###### /etc/profile
   export PATH=xxx/xxx/bin:$PATH 
   ######  

   source /etc/profile
   ```

7. 测试是否安装成功

   ```sh
   magick -version
   > Version: ImageMagick 7.0.9-13 Q16 x86_64 2020-01-03 https://imagemagick.org
   ```

8. 查看转换列表

   ImageMagick7 将 `convert` 指令改为了 `magick`，这点在使用命令行工具时需要注意：

   ```sh
   magick -list format | grep webp
   > WEBP* WEBP      rw+   WebP Image Format (libwebp 0.6.1 [020E])
   ```

接下来就可以使用命令行工具对图片进行转换：

```sh
magick test.png test.webp
```

# 4. PHP 插件 imagick 的使用

如果没有 webp 格式转换的需求，可以直接用 apt 安装 php-imagick 插件即可直接使用，但是 php-imagick 默认安装的 ImageMagick 是 6.x 版本的，也就是说不会支持 webp，因此还是要按照以下方式手动源码安装 imagick 插件。

1. 到[官网](https://pecl.php.net/package/imagick)下载最新版本的 imagick 插件

   这里以3.4.4版本为例：

   ```sh
   wget https://pecl.php.net/get/imagick-3.4.4.tgz
   tar -zxvf imagick-3.4.4.tgz
   cd imagick-3.4.4
   ```

2. 安装 PHP 插件

   ```sh
   phpize
   # /usr/local/php/bin/php-config 为 php 的配置路径，根据机器的情况设置
   # /usr/local/imagemagick 为刚才安装的 ImageMagick7 的路径
   ./configure --with-php-config=/usr/local/php/bin/php-config --with-imagick=/usr/local/imagemagick
   make && make install
   ```

Demo 示例：https://github.com/EsunR/Imagick-Demo


