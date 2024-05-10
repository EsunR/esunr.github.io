---
title: CSS3选择器的 nth-child 与 nth-of-type
tags: []
categories:
  - 前端
  - CSS
date: 2019-12-01 15:42:01
---

# 吐槽

CSS3 的选择器文档说明简直让人看的头大，每一句话都搞得跟阅读理解一样，就算读通了也没有办法理解，所以就在这里好好研究一下 CSS3 的选择器到底选择目标是什么。

# nth-child

> 官方解释：`p:nth-child(2)` 规定属于其父元素的第二个子元素的每个 p 的背景色

最难让我头大的就是这个 `nth-child` 本身不难理解，就是选择对应父级的第 n 个节点元素，比如：

```css
/* 基础样式，分离每个 .wrapper 下的子元素 */
.wrapper>* {
  border: 2px solid pink;
  margin: 5px 0;
}

.wrapper :nth-child(2) {
  background-color: skyblue;
}
```

```html
<div class="wrapper">
  <p>i'm p</p>
  <div class="inner">
    <ul>
      <li>2222</li>
      <li>2222</li>
      <li>2222</li>
    </ul>
    <ul>
      <li>2222</li>
      <li>2222</li>
      <li>2222</li>
    </ul>
  </div>
  <li>2333</li>
  <li>2333</li>
  <li>2333</li>
  <li>2333</li>
  <li>2333</li>
  <li>2333</li>
  <p>i'm p too</p>
  <p>i'm div</p>
</div>
```

![](https://i.loli.net/2019/12/01/EnRM6Q5wbmPZUxN.png)

但是恶心就恶心在，在这里使用的伪类是后缀与一个空选择器上，所以就直接表示为父元素的第二个子元素，那么如果我们为其前面加上一个 `li`，那就变成了：

```css
.wrapper li:nth-child(2) {
  background-color: skyblue;
}
```

![](https://i.loli.net/2019/12/01/7IGbWzC2lrFAt8y.png)

经过一翻思想斗争，终于悟出了这里的语法解释意思为：选择 `.wrapper` 下的每个 `li` 元素，然后看这个 `li` 元素是否是其父级元素的第二个子元素，如果是就应用样式，如果不是就不应用样式。

我们要理解普通选择器是向下查找，每次添加条件，而伪类是用来过滤选择到的元素。

============= 以下为 2024 年新增： ============

再看前面的示例，最开始的理解其实是错的，不是说伪类选择器前面没有挨着其他选择器就表示匹配当前元素的第 n 个元素了，而是如果伪类选择器没有指定任何其他选择器的话，就说明匹配前面选择器下匹配到的所有元素，换句话说

```css
.wrapper :nth-child(2) {
  background-color: skyblue;
}
```

就等同于：

```css
.wrapper *:nth-child(2) {
  background-color: skyblue;
}
```

表示为匹配 `.wrapper` 元素下所有属于父元素的第二个子元素的元素，背景颜色都变为 `skyblue`，那匹配到的 DOM 节点就应该为：

```html
```html
<div class="wrapper">
  <p>i'm p</p>
  <div class="inner"> <!-- 匹配到，背景颜色设置为 blue -->
    <ul>
      <li>2222</li>
      <li>2222</li> <!-- 匹配到，背景颜色设置为 blue -->
      <li>2222</li>
    </ul>
    <ul> <!-- 匹配到，背景颜色设置为 blue -->
      <li>2222</li>
      <li>2222</li> <!-- 匹配到，背景颜色设置为 blue -->
      <li>2222</li>
    </ul>
  </div>
  <li>2333</li>
  <li>2333</li>
  <li>2333</li>
  <li>2333</li>
  <li>2333</li>
  <li>2333</li>
  <p>i'm p too</p>
  <p>i'm div</p>
</div>
```

只是前面贴的图片看不出来而已。

# last-child

```css
.wrapper li:last-child {
  background-color: skyblue;
}
```

![](https://i.loli.net/2019/12/01/OUkoEIPAaRQ4tKY.png)

# first-child

```css
.wrapper li:first-child {
  background-color: skyblue;
}
```

![](https://i.loli.net/2019/12/01/76jk8dcLsuUGbtE.png)

# nth-of-type

> 官方解释：`p:nth-of-type(2)` 选择每个p元素是其父级的第二个p元素	

我们按照刚才的思路去理解这个选择器，其流程为：选择 `.wrapper` 下的所有 `li` 元素，如果其在当前的同类型的兄弟节点中排第二个，那么就应用样式，否则不应用：

```css
.wrapper li:nth-of-type(2) {
  background-color: skyblue;
}
```

![](https://i.loli.net/2019/12/01/UfrIEFSnvN2Vt4y.png)

但是如果前面不加 `li`，而应用于 `.wrapper` 下的每个元素，那么就会变成：

```
.wrapper :nth-of-type(2) {
  background-color: skyblue;
}
```

![](https://i.loli.net/2019/12/01/N2QHjxTtnbIXf9i.png)

这个是因为没有规定子级的过滤元素，那么在匹配到每个新的标签类型时，都会验证其在兄弟节点相同的标签类型下，其是否是第2个，如果是就应用样式，如果不是就不应用样式

# 权重问题

CSS 的伪类选择器权重与 class 选择器权重是同等级的，举个例子：

```html
<div class="wrapper">
  <div class="child">div</div>
  <div class="child">div</div>
  <li class="child">li</li>
  <li class="child">li</li>
</div>
```

```css
.wrapper .child {
  background-color: pink;
}

.wrapper :nth-of-type(2) {
  background-color: skyblue;
}
```

![](https://i.loli.net/2019/12/01/lSwPCH1p6BkLaxQ.png)

同等级下，伪类选择器的效果覆盖了 class 选择器

```css
.wrapper :nth-of-type(2) {
  background-color: skyblue;
}

.wrapper .child {
  background-color: pink;
}
```

![](https://i.loli.net/2019/12/01/9TGyMjkSzHsgulq.png)

调换位置后，class选择器覆盖了伪类选择器的效果