---
title: 关于 Stylus 的常用技巧
tags:
  - CSS
  - stylus
categories:
  - 前端
  - CSS
date: 2023-12-29 17:43:25
---
[Stylus Playground](https://stylus-lang.com/try.html)

# 1. 选择器

## Parent 选择器

 `&` 字符可以用于父级选择器：

```styl
textarea
input
  color #A7A7A7
  &:hover
    color #000
```

编译为：

```css
textarea,
input {
  color: #a7a7a7;
}
textarea:hover,
input:hover {
  color: #000;
}
```

## 部分选择器

你可以在任意位置使用部分选择器（Partial Reference）向上选中已有的选择器，使用 `^[N]` 表示。

当 N 为正数时，代表从上向下数第 N 个选择器：

```styl
.foo
	&__bar
		.text
			color red
			
			^[0].is-primary
				.text
					color green
```

编译为：

```css
.foo__bar .text {
  color: #f00;
}
.foo.is-primary .text {
  color: #008000;
}
```

> `^[0]` 可以直接使用 `/.` 根选择器（[Root Reference](https://stylus-lang.com/docs/selectors.html#root-reference)）来代替。

N 为负数时，表示从当前选择器向上第 N 位的的选择器：

```styl
.foo
	&__bar
		.text
			color red
			
			^[-1].is-primary
				.text
					color green
```

编译后：

```css
.foo__bar .text {
  color: #f00;
}
.foo__bar.is-primary .text {
  color: #008000;
}
```

合理的结合父级选择器 `&` 可以保留当前选择器的层级，从简化 CSS 的写法，比如 `.foo` 元素有一个 `.is-primary` 的状态，希望在该状态下 `.text` 元素的颜色为 `green`，就可以写为：

```styl
.foo
	&__bar
		.text
			color red
			
			^[0].is-primary &
				color green
```

编译后：

```css
.foo__bar .text {
  color: #f00;
}
.foo.is-primary .foo__bar .text {
  color: #008000;
}
```