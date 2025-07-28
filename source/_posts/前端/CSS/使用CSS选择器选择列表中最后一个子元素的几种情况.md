---
title: 使用CSS选择器选择列表中最后一个子元素的几种情况
tags:
  - CSS
categories:
  - 前端
  - CSS
date: 2025-07-08 10:49:26
---

# 1. 情况一：选择列表中最后一个子元素

假设现在有这么一个列表结构：

```html
<style>
.list {
	padding: 10px;
	margin-bottom: 20px;
	background-color: #f0f0f0;
}

.list-item {
	display: flex;
	flex-direction: column;
	align-items: center;
	justify-content: center;
	width: 100px;
	height: 100px;
	background-color: #fff;
	margin-bottom: 20px;
	border: 1px solid #ccc;
}
</style>

<div class="list">
	<div class="list-item"></div>
	<div class="list-item"></div>
	<div class="list-item"></div>
</div>
```

<img src="https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202507071051119.png" width="250"/>

如果我们希望最后一个 `list-item` 添加一个 `background-color`，会很快想到 `last-child` 选择器，并写出如下的 css：

```css
.list-item:last-child {
	background-color: pink;
}
```

这个选择器的意思表示在文档中最后一个子元素如果是 `.list-item` 的话，`background-color` 就设置为 `pink`。对上面的文档结构是生效的，但是不够严谨，假如页面中还有一个其他的 list 也嵌套了 `.list-item` 元素，比如：

```html
<div class="list">
	<div class="list-item"></div>
	<div class="list-item"></div>
	<div class="list-item"></div>
</div>
<div class="list2">
	<div class="list-item"></div>
	<div class="list-item"></div>
	<div class="list-item"></div>
</div>
```

那么 `.list2` 中的 `.list-item` 也会被设置为 `background-color: pink`，因为它是属于 `.list2` 元素的 last child。

<img src="https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202507071053857.png" width="250" />

因此为了避免出现这种情况，使用 `last-child` 伪类的时候我们应该尽可能的指定具体是那个元素下的 last child，对于我们当前的示例来说，就是 `.list` 的 last child，因此，选择器应该写为：

```css
.list .list-item:last-child {
	margin-bottom: 0px;
}
```

但是如果存在 `.list-item` 元素是 `.list` 元素的孙子元素，比如：

```html
<div class="list">
	<div class="list-item"></div>
	<div class="list-item"></div>
	<div class="list-item">
		<div class="list-item"></div>
		<div class="list-item"></div>
	</div>
</div>
```

`.list-item` 中嵌套的 `.list-item` 也被选择器 `.list .list-item:last-child` 命中：

<img src="https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202507071057970.png" width="250"/>

因此我们一定要再次缩紧选择器的选中范围，这时候就要使用 `>` 子组合器，明确自定只有 `.list` 元素下的直接子元素 `.list-item` 是其最后一个子元素时才命中：

```css
.list .list-item:last-child {
	background-color: pink;
}
```

<img src="https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202507071101169.png" width="250"/>

此外，如果我们对于最后一个元素的 class name 没有要求的话，也可以不用指定 classname，直接写为：

```css
.list > :last-child { /** 等同与 .list > *:last-child */
	background-color: pink;
}
```

就表示选中类表中**任意**最后一个**直接**子元素。

# 2. 情况二：选择列表中某种标签的最后一个子元素

如果想要选择列表中最后某类标签的最后一个子元素，可以使用 `last-of-type` 选择器：

```html
<div class="list">
	<div class="list-item"></div>
	<div class="list-item"></div>
	<div class="list-item"></div>
	<p>This is P element</p>
	<p>This is P element</p>
</div>
```

```css
.list > div:last-of-type {
	background-color: pink;
}
```

表示选中 `.list` 元素中的直接子元素里的最后一个 div 元素：

<img src="https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202507071400197.png" width="250"/>

这时候不得不提一句 `last-of-type` 与 classname 相结合的情况：

```css
.list > .list-item:last-of-type {
	background-color: pink;
}
```

当 `.list-item` 类选择器与 `:last-of-type` 结合的时候，首先查看 `.list-item` 是什么元素，并且查看拥有 `.list-item` 类名的元素是否是该类元素的最后一个，举例来说：

```html
<div class="list">
	<div class="list-item"></div>
	<div class="list-item"></div>
	<!-- ↓ 会选中该元素 -->
	<div class="list-item"></div>
	
	<p class="list-item">This is P element</p>
	<!-- ↓ 会选中该元素 -->
	<p class="list-item">This is P element</p>
	
	<span class="list-item">This is Span element</p>
	<!-- ↓ 不会选中该元素，因为拥有 list-item 类名的元素不是最后一个 span 元素 -->
	<span class="list-item">This is Span element</p>
	<span>This is Span element</p>
</div>
```

# 3. 情况三：选择列表中某个 class name 的最后一个子元素

如果想要选中列表中最后一个 class name 为 `.list-item` 的元素，比如：

```html
<div class="list">
	<div class="list-item"></div>
	<div class="list-item"></div>
	<!-- ↓ 想选中这个元素 -->
	<div class="list-item"></div>
	<div>This is Div element</p>
	<div>This is Div element</p>
</div>
```

与上面不同的是列表中 `.list-item` 绑定的 div 元素并不是 `.list` 中的最后一个 div，因此不能使用 `:last-of-type`。

这时候我们可以使用 `:nth-last-child` 结合 `of <selector>` 语法来选中 `.list` 中的最后一个 `.list-item` 元素：

```css
.list > :nth-last-child(1 of .list-item) {
	background-color: pink;
}
```

上面的选择器的意思为：在 `.list` 的直接直接点中，从后往前数，命中 `.list-item` 选择器的第一个元素，也就是选取列表中的最后一个 `.list-item` 元素。

但是需要注意的是，虽然浏览器很早就支持了 `nth-child`、`nth-last-child`，但是对于 `of <selector>` 语法是 CSS4 才支持的，Chrome 需大于 111（2023年发布），Safari 需 大于 9（2015年发布），IE 则完全不支持，兼容列表如下：

![image.png|700](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202507081047021.png)
