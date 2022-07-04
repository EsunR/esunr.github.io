---
title: Vue 中销毁 keep-alive 缓存组件及缓存组件的管理
tags:
  - Vue
categories:
  - 前端
  - Vue
date: 2019-10-23 22:23:53
---
# 1. keep-alive
在 Vue 的组件机制中，如果在多个组件页面中来回切换，已访问的组件页面是不会被缓存的，也就是说每次切换一个组件页面再返回后，原有的组件页面仍会被重新渲染，相应的执行从 `beforeCreate` 开始的声明周期函数 。这样的话是非常浪费性能的，所以 Vue 提供了一个 [\<keep-alive\> 组件](https://cn.vuejs.org/v2/api/#keep-alive)，可以用于缓存组件，配合 Vue-Router 使用可以缓存页面。

但是这样就存在一个问题，Vue 并没有专门的销毁缓存组件的方法，这就造成缓存的组件会一直存在，如果我们需要重新加载这个组件，或更新组件中的数据，是没有办法主动让组件及其子组件重新渲染的。

# 2. 问题解决
为了解决以上问题我们可以通过 `<keep-alive>` 组件的 `include` 属性来解决，我们先来看一下官方的释义：

**`include` and `exclude`**

> 2.1.0 新增

`include` 和 `exclude` 属性允许组件有条件地缓存。二者都可以用逗号分隔字符串、正则表达式或一个数组来表示：

```html
<!-- 逗号分隔字符串 -->
<keep-alive include="a,b">
  <component :is="view"></component>
</keep-alive>

<!-- 正则表达式 (使用 `v-bind`) -->
<keep-alive :include="/a|b/">
  <component :is="view"></component>
</keep-alive>

<!-- 数组 (使用 `v-bind`) -->
<keep-alive :include="['a', 'b']">
  <component :is="view"></component>
</keep-alive>
```

匹配首先检查组件自身的 `name` 选项，如果 `name` 选项不可用，则匹配它的局部注册名称 (父组件 `components` 选项的键值)。匿名组件不能被匹配。

**简而言之，我们可以通过控制 `include` 属性的值，来控制系统缓存的组件。**

# 3. 解决方案

1. 使用 vuex 或者 localstroge 等全局存储方案，创建一个数组 `keepAliveArr`
2. 将缓存组件的 name 存放于 `keepAliveArr` 数组中
3. 将 `keepAliveArr` 绑定到 `<keep-alive>` 的 `include` 属性上
4. 当需要删除缓存组件时，直接删除 `keepAliveArr` 中的组件 name
5. 当需要添加缓存组件时，向 `keepAliveArr` 中添加组件的 name