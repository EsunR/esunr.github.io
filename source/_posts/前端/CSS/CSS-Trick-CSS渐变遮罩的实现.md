---
title: '[CSS Trick] CSS渐变遮罩的实现'
tags:
  - CSS
categories:
  - 前端
  - CSS
date: 2021-08-06 18:13:10
---

# 1. 前言

在设计稿中，经常遇到渐变场景，说到渐变那必须要谈及 `linear-gradient`，这里推荐去看《CSS 揭秘》一书中对渐变的介绍。

大部分我们都是在 `background` 中去使用 `linear-gradient`，来实现一个渐变背景。但是在一些场景下，我们希望内容部分有个整体的渐变，比如这张设计图：

![](https://i.loli.net/2021/08/06/BbVJivP7pYyksK6.png)

进度条的实现比较简单，但是进度条的下方有一个整体的渐变效果，这该如何实现呢？

如果我们想法设法的去把进度条做成渐变效果，那么方向就错了。如果你熟悉 PhotoShop，那么就会想到利用 `遮罩` 这个概念来实现这个效果，CSS 里正好也提供了一个 `mask-image` 的遮罩属性。

# 2. 实现

我们可以使用 `mask-image` 与 `linear-gradient` 结合，创建一个遮罩层，我们将这个遮罩层放在一个普通的 div 上先试试看：

```html
<div class="container"></div>
```

```css
.container {
  width: 200px;
  height: 200px;
  background-color: pink;
  -webkit-mask-image: linear-gradient(#000000, transparent);
}
```

![](https://i.loli.net/2021/08/06/frazPU5HQNnvJEt.png)

我们可以看出 div 从上倒下都有一个渐变的效果，如果我们只想让底部边缘渐变，可以设置一下渐变的起始位置：

```css
.container {
  width: 200px;
  height: 200px;
  background-color: pink;
  /* 只从底部 100px 的位置开始渐变 */
  -webkit-mask-image: linear-gradient(#000000 calc(100% - 100px), transparent);
}
```

![](https://i.loli.net/2021/08/06/juRf7dDCQpL6Z3z.png)

应用到环形进度条上：

```html
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Document</title>
  <style>
    .container {
      height: 150px;
      overflow: hidden;
      position: relative;
      -webkit-mask-image: linear-gradient(#121212 calc(100% - 100px), transparent);
    }

    .bg {
      width: 300px;
      height: 300px;
      border-radius: 300px;
      border: 10px solid #4092FE;
      border-bottom-color: transparent;
      border-left-color: transparent;
      transform: rotate(-45deg);
    }

    .fill {
      width: 300px;
      height: 300px;
      border-radius: 300px;
      border: 10px solid #B4DDFE;
      border-bottom-color: transparent;
      border-left-color: transparent;
      transform: rotate(90deg);
      position: absolute;
      top: 0;
    }
  </style>
</head>

<body>
  <div class="container">
    <div class="bg"></div>
    <div class="fill"></div>
  </div>
</body>

</html>
```

![](https://i.loli.net/2021/08/06/aF2hqwDV5mRWrbL.png)