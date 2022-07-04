---
title: 对Vue2.2中监听子组件事件的理解
tags:
  - Vue
categories:
  - 前端
  - Vue
date: 2019-02-17 21:44:44
---
[官方文档](https://cn.vuejs.org/v2/guide/components.html#%E7%9B%91%E5%90%AC%E5%AD%90%E7%BB%84%E4%BB%B6%E4%BA%8B%E4%BB%B6)

## 解释
所谓的 `监听子组件事件` ，就是当子组件内部触发了一个事件后，外部（也就是调用子组件的父级组件）应该能相应的感知到事件的触发，从而再出发一些列的操作。

例如：子组件为一个按钮，当按钮被点击时，父级组件会感知，并触发想要触发的操作。

## 实现思路
**1.设定埋伏，准备捕捉子组件的操作**

我们都知道，`v-on`操作可以用来监听某些预设好的事件，如input、change、click事件，同时也支持访问自定义的事件。所以，当我们调用已注册的组件，如`<blog-post>`组件，我们可以用`v-on`为组件预先绑定一个自定义的事件监听器，只要这个自定义事件被触发了，父级组件就会感知到，触发一个操作。具体的预先设置如下：
```html
<blog-post
  ...
  v-on:enlarge-text="postFontSize += 0.1"
></blog-post>
```
由此可见，我们监听的自定义事件命名为`enlarge-text`，捕捉到事件之后进行的操作为`postFontSize += 0.1`(postFontSize是Vue示例内部data部分的一个数据)。

**2.子组件进行操作，告知父组件**

我们再第一步设好了埋伏，创建了一个自定义事件，然后我们便需要在子组件中设置这个自定义事件是如何触发的，这里我们用到了`$emit`。

`$emit`可以触发一个自定义事件，那么我们只要在子组件中使用`$emit('enlarge-text')`就可以告知父组件**子组件触发了相应的动作**。
```html
Vue.component('blog-post', {
  ...
  template: `
	<button v-on:click="$emit('enlarge-text')">
	  Enlarge text
	</button>
  `
})
```
如上，当子组件中的按钮被点击时，就触发了`$emit('enlarge-text')`，间接触发了`enlarge-text`自定义事件，然后触发了父组件调用子组件时设置的`v-on:enlarge-text`，最终触发了`postFontSize += 0.1`操作。

> Note：要注意`$emit`只是用来触发一个自定义的事件，这个事件对应外部父组件调用子组件时，对子组件添加的`v-on`所监听的事件，`$emit`并不能触发任何函数操作，仅仅如同一个触发器。