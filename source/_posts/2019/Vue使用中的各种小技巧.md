---
title: Vue使用中的各种小技巧（转载）
tags: [Vue]
categories:
  - Front
  - Vue
date: 2019-10-28 22:24:45
---
### Watch immediate

这个已经算是一个比较常见的技巧了，这里就简单说一下。当 watch 一个变量的时候，初始化时并不会执行，如下面的例子，你需要在`created`的时候手动调用一次。

```
// bad
created() {
  this.fetchUserList();
},
watch: {
  searchText: 'fetchUserList',
}
复制代码
```

你可以添加`immediate`属性，这样初始化的时候也会触发，然后上面的代码就能简化为：

```
// good
watch: {
  searchText: {
    handler: 'fetchUserList',
    immediate: true,
  }
}
复制代码
```

ps: watch 还有一个容易被大家忽略的属性`deep`。当设置为`true`时，它会进行深度监听。简而言之就是你有一个 `const obj={a:1,b:2}`，里面任意一个 key 的 value 发生变化的时候都会触发`watch`。应用场景：比如我有一个列表，它有一堆`query`筛选项，这时候你就能`deep watch`它，只有任何一个筛序项改变的时候，就自动请求新的数据。或者你可以`deep watch`一个 form 表单，当任何一个字段内容发生变化的时候，你就帮它做自动保存等等。

### Attrs 和 Listeners

这两个属性是 `vue 2.4` 版本之后提供的，它简直是二次封装组件或者说写高阶组件的神器。在我们平时写业务的时候免不了需要对一些第三方组件进行二次封装。比如我们需要基于`el-select`分装一个带有业务特性的组件，根据输入的 name 搜索用户，并将一些业务逻辑分装在其中。但`el-select`这个第三方组件支持几十个配置参数，我们当然可以适当的挑选几个参数通过 props 来传递，但万一哪天别人用你的业务组件的时候觉得你的参数少了，那你只能改你封装的组件了，亦或是哪天第三方组件加入了新参数，你该怎么办？

其实我们的这个组件只是基于`el-select`做了一些业务的封装，比如添加了默认的`placeholder`，封装了远程 ajax 搜索请求等等，总的来说它就是一个中间人组件，只负责传递数据而已。

这时候我们就可以使用`v-bind="$attrs"`：传递所有属性、`v-on="$listeners"`传递所有方法。如下图所示：

![](https://imgconvert.csdnimg.cn/aHR0cHM6Ly91c2VyLWdvbGQtY2RuLnhpdHUuaW8vMjAxOS80LzI0LzE2YTRlODJiMjhmMmIyNGM?x-oss-process=image/format,png)

这样，我们没有在`$props`中声明的方法和属性，会通过`$attrs`、`$listeners`直接传递下去。这两个属性在我们平时分装第三方组件的时候非常有用！

### .sync

这个也是 `vue 2.3` 之后新加的一个语法糖。这也是平时在分装组件的时候很好用的一个语法糖，它的实现机制和`v-model`是一样的。

![](https://imgconvert.csdnimg.cn/aHR0cHM6Ly91c2VyLWdvbGQtY2RuLnhpdHUuaW8vMjAxOS81LzEwLzE2YWEwNmJhZDM3OWVmZmY?x-oss-process=image/format,png)

当你有需要在子组件修改父组件值的时候这个方法很好用。 线上 [例子](https://github.com/PanJiaChen/vue-element-admin/blob/master/src/components/Pagination/index.vue)

### Computed 的 get 和 set

`computed` 大家肯定都用过，它除了可以缓存计算属性外，它在处理传入数据和目标数据格式不一致的时候也是很有用的。set、get [文档](https://cn.vuejs.org/v2/guide/computed.html#%E8%AE%A1%E7%AE%97%E5%B1%9E%E6%80%A7%E7%9A%84-setter)

上面说的可能还是是有点抽象，举一个简单的的例子：我们有一个 form 表单，from 里面有一个记录创建时间的字段`create_at`。我们知道前端的时间戳都是 13 位的，但很多后端默认时间戳是 10 位的，这就很蛋疼了。前端和后端的时间戳位数不一致。最常见的做法如下：

![](https://imgconvert.csdnimg.cn/aHR0cHM6Ly91c2VyLWdvbGQtY2RuLnhpdHUuaW8vMjAxOS81LzcvMTZhOTEzODc3NjJjMjZkMg?x-oss-process=image/format,png)

上面的代码主要做的是：在拿到数据的时候将后端 10 位时间戳转化为 13 位时间戳，之后再向服务端发送数据的时候再转化回 10 位时间戳传给后端。目前这种做法当然是可行的，但之后可能不仅只有创建接口，还有更新接口的时候，你还需要在`update`的接口里在做一遍同样数据转化的操作么？而且这只是一个最简单的例子，真实的 form 表单会复杂的多，需要处理的数据也更为的多。这时候代码就会变得很难维护。

这时候就可以使用 computed 的 set 和 get 方法了。

![](https://imgconvert.csdnimg.cn/aHR0cHM6Ly91c2VyLWdvbGQtY2RuLnhpdHUuaW8vMjAxOS81LzkvMTZhOWI2MjllOTgyNzExNQ?x-oss-process=image/format,png)

通过上面的代码可以看到，我们把需要做前后端兼容的数据，放在了 computed 中，从 `getData`和`submit`中隔离了数据处理的部分。

当然上面说的方案还不是最好的方案，你其实应该利用之前所说的`v-bind="$attrs"`和`v-on="$listeners"`对时间选择器组件进行二次封装。例如这样`<date-time v-model="postForm.create_at" />` 外部无需做任何数据处理，直接传入一个 10 位的时间戳，内部进行转化。当日期发生变化的时候，自动通过`emit`触发`input`使`v-model`发生变化，把所有脏活累活都放在组件内部完成，保持外部业务代码的相对干净。具体 v\-model 语法糖原理可以见官方 [文档](https://cn.vuejs.org/v2/guide/components.html#%E5%9C%A8%E7%BB%84%E4%BB%B6%E4%B8%8A%E4%BD%BF%E7%94%A8-v-model)。

set 和 get 处理可以做上面说的进行一些数据处理之外，你也可以把它当做一个 `watch`的升级版。它可以监听数据的变化，当发生变化时，做一些额外的操作。最经典的用法就是`v-model`上绑定一个 vuex 值的时候，input 发生变化时，通过 `commit`更新存在 vuex 里面的值。

![](https://imgconvert.csdnimg.cn/aHR0cHM6Ly91c2VyLWdvbGQtY2RuLnhpdHUuaW8vMjAxOS81LzcvMTZhOTE2ZjA4ZDk1MWY0NQ?x-oss-process=image/format,png)

具体的解释你也可以见官方 [文档](https://vuex.vuejs.org/zh/guide/forms.html)

### Object.freeze

这算是一个性能优化的小技巧吧。在我们遇到一些 `big data`的业务场景，它就很有用了。尤其是做管理后台的时候，经常会有一些超大数据量的 table，或者一个含有 n 多数据的图表，这种数据量很大的东西使用起来最明显的感受就是卡。但其实很多时候其实这些数据其实并不需要响应式变化，这时候你就可以使用 [Object.freeze](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Object/freeze) 方法了，它可以冻结一个对象(注意它不并是 vue 特有的 api)。

当你把一个普通的 JavaScript 对象传给 Vue 实例的 data 选项，Vue 将遍历此对象所有的属性，并使用 `Object.defineProperty` 把这些属性全部转为 `getter/setter`，它们让 Vue 能进行追踪依赖，在属性被访问和修改时通知变化。 使用了 `Object.freeze` 之后，不仅可以减少 `observer` 的开销，还能减少不少内存开销。相关 [issue](https://github.com/vuejs/vue/issues/4384)。

使用方式：`this.item = Object.freeze(Object.assign({}, this.item))`

这里我提供了一个在线测速 demo，[点我](https://panjiachen.gitee.io/panjiachen.github.io/big-table/index.html)。

通过测速可以发现正常情况下`1000 x 10` rerender 都稳定在 1000ms\-2000ms 之间，而开启了`Object.freeze`的情况下，rerender 都稳住在 100ms\-200ms 之间。有接近 10 倍的差距。所以能确定不需要变化检测的情况下，`big data` 还是要优化一下的。

### Functional

[函数式组件](https://cn.vuejs.org/v2/guide/render-function.html#%E5%87%BD%E6%95%B0%E5%BC%8F%E7%BB%84%E4%BB%B6) 这个是文档里就写的内容，但在其实很少人会刻意的去使用。因为你不用它，代码也不会有任何问题，用了到可能会出现 bug。

我们先看一个例子：[点我测试性能](https://vue-9-perf-secrets.netlify.com/bench/functional) 肉眼可见的性能差距。当然很多人会觉得我的项目中也没有这种变化量级，但我觉得这是一个程序员的自我修养问题吧。，比如能用`v-show`的地方就不要用`v-if`，善用`keep-alive`和`v-once`，`Object.freeze()`处理 [vue big data](https://github.com/vuejs/vue/issues/4384) 问题等。虽然都是一些小细节，但对性能和体验都是有不少的提升的。更多的性能优化技巧请查看该文章 [vue\-9\-perf\-secrets](https://slides.com/akryum/vueconfus-2019#/)

### 减少全局操作

这其实并不只是针对 vue 项目的一个建议，我们平时写代码的时候一定要尽量避免一些全局的操作。如果必须要用到的时候，一定要自己检查，会不会产生一些全局的污染或者副作用。

举几个简单例子：

1.  我们现在虽然用 vue 写代码了，核心思想转变为用数据驱动 `view`，不用像`jQuery`时代那样，频繁的操作 DOM 节点。但还是免不了有些场景还是要操作 DOM 的。我们在组件内选择节点的时候一定要切记避免使用 `document.querySelector()`等一系列的全局选择器。你应该使用`this.$el`或者`this.refs.xxx.$el`的方式来选择 DOM。这样就能将你的操作局限在当前的组件内，能避免很多问题。

2.  我们经常会不可避免的需要注册一些全局性的事件，比如监听页面窗口的变化`window.addEventListener('resize', this.__resizeHandler)`，但再声明了之后一定要在 `beforeDestroy`或者`destroyed`生命周期注销它。`window.removeEventListener('resize', this.__resizeHandler)`避免造成不必要的消耗。

3.  避免过多的全局状态，不是所有的状态都需要存在 vuex 中的，应该根据业务进行合理的进行取舍。如果不可避免有很多的值需要存在 vuex 中，建议使用动态注册的方式。相关[文档](https://vuex.vuejs.org/zh/guide/modules.html#%E6%A8%A1%E5%9D%97%E5%8A%A8%E6%80%81%E6%B3%A8%E5%86%8C)。只是部分业务需要的状态处理，建议使用 `Event Bus`或者使用 [简单的 store 模式](https://cn.vuejs.org/v2/guide/state-management.html#%E7%AE%80%E5%8D%95%E7%8A%B6%E6%80%81%E7%AE%A1%E7%90%86%E8%B5%B7%E6%AD%A5%E4%BD%BF%E7%94%A8)。

4.  css 也应该尽量避免写太多的全局性的样式。除了一些全局公用的样式外，所以针对业务的或者组件的样式都应该使用命名空间的方式或者直接使用 vue\-loader 提供的 `scoped`写法，避免一些全局冲突。[文档](https://panjiachen.gitee.io/vue-element-admin-site/zh/guide/essentials/style.html#css-modules)

### Sass 和 Js 之间变量共享

这个需求可能有些人没有遇到过，举个实际例子来说明一下。

![](https://imgconvert.csdnimg.cn/aHR0cHM6Ly91c2VyLWdvbGQtY2RuLnhpdHUuaW8vMjAxOS8zLzI3LzE2OWJlOTlmNmJjMjM0M2M?x-oss-process=image/format,png)

如上面要实现一个动态的换肤，就需要将用户选择的 theme 主题色传递给 css。但同时初始化的时候 css 又需要将一个默认主题色传递给 js。所以下面我们就分两块来讲解。

*   js 将变量传递给 sass 这部分是相对简单就可以实现的，实现方案也很多。最简单的方法就是通过 在模板里面写 style 标签来实现，就是俗话所说的内联标签。

    ```
    <div :style="{'background-color':color}" ></div>
    复制代码
    ```

    或者使用 `css var()`，在线 [demo](https://codepen.io/richardtallent/pen/yvpERW/)，还有用 less 的话`modifyVars`，等等方案都能实现 js 与 css 的变量传递。

*   sass 将变量给 js

还是那前面那个换肤来举例子，我们页面初始化的时候，总需要一个默认主题色吧，假设我们在 `var.scss`中声明了一个 `theme:blue`，我们在 js 中该怎么获取这个变量呢？我们可以通过 [css\-modules](https://github.com/css-modules/icss#export) `:export`来实现。更具体的解释\- [How to Share Variables Between Javascript and Sass](https://www.bluematador.com/blog/how-to-share-variables-between-js-and-sass)

```
// var.scss
$theme: blue;

:export {
  theme: $theme;
}
复制代码
```

```
// test.js
import variables from '@/styles/var.scss'
console.log(variables.theme) // blue
复制代码
```

当 js 和 css 共享一个变量的时候这个方案还是很实用的。vue\-element\-admin 中的侧边栏的宽度，颜色等等变量都是通过这种方案来实现共享的。

其它换肤方案可以参考 [聊一聊前端换肤](https://juejin.im/post/5ca41617f265da3092006155)。

### 自动注册全局组件

我的业务场景大部分是中后台，虽然封装和使用了很多第三方组件，但还是免不了需要自己封装和使用很多业务组件。但每次用的时候还需要手动引入，真的是有些麻烦的。

![](https://imgconvert.csdnimg.cn/aHR0cHM6Ly91c2VyLWdvbGQtY2RuLnhpdHUuaW8vMjAxOS8zLzI3LzE2OWJlNDBkNWFjMDU2OTk?x-oss-process=image/format,png)

我们其实可以基于 webpack 的`require.context`来实现自动加载组件并注册的全局的功能。相关原理在之前的文章中已经阐述过了。具体代码如下

![](https://imgconvert.csdnimg.cn/aHR0cHM6Ly91c2VyLWdvbGQtY2RuLnhpdHUuaW8vMjAxOS8zLzI3LzE2OWJlNDU3NWRjMjQzZDk?x-oss-process=image/format,png)

我们可以创建一个`GlobalComponents`文件夹，将你想要注册到全局的组件都放在这个文件夹里，在`index.js`里面放上如上代码。之后只要在入口文件`main.js`中引入即可。

```
//main.js
import './components/Table/index' // 自动注册全局业务组件
复制代码
```

这样我们可以在模板中直接使用这些全局组建了。不需要再繁琐的手动引入了。

```
<template>
  <div>
    <user-select/>
    <status-button/>
  </div>
</template>
复制代码
```

当然你也不要为了省事，啥组件都往全局注册，这样会让你初始化页面的时候你的初始`init bundle`很大。你应该就注册那些你经常使用且体积不大的组件。那些体积大的组件，如编辑器或者图表组件还是按需加载比较合理。而且你最好声明这些全局组件的时候有一个统一的命名规范比如：`globel-user-select`这样的，指定一个团队规范，不然人家看到你这个全局组件会一脸懵逼，这个组件是哪来的。

### Lint

这又是一个老生常谈的问题了 vue 的一些最佳实践什么的话，这里不讨论了，我觉得看官方的 [风格指南](https://cn.vuejs.org/v2/style-guide/) 差不多就够了。比如避免`避免 v-if 和 v-for 用在一起`、`元素特性的顺序`这些等等规则，几十条规则，说真的写了这么久 vue，我也只能记住一些常规的。什么属性的顺序啊，不太可能记住的。这种东西还是交给程序来自动优化才是更合理的选择。强烈推荐配置编辑器自动化处理。具体配置见 [文档](https://panjiachen.gitee.io/vue-element-admin-site/zh/guide/advanced/eslint.html)。同时建议结合 `Git Hooks` 配合在每次提交代码时对代码进行 lint 校验，确保所有提交到远程仓库的代码都符合团队的规范。它主要使用到的工具是`husky`和`lint-staged`，详细文档见 [Git Hooks](https://panjiachen.gitee.io/vue-element-admin-site/zh/guide/advanced/git-hook.html#git-hooks)

### Hook

这个是一个文档里没有写的 api，但我觉得是一个很有用的 api。比如我们平时使用一些第三方组件，或者注册一些全局事件的时候，都需要在`mounted`中声明，在`destroyed`中销毁。但由于这个是写在两个生命周期内的，很容易忘记，而且大部分在创建阶段声明的内容都会有副作用，如果你在组件摧毁阶段忘记移除的话，会造成内存的泄漏，而且都不太容易发现。如下代码：

![](https://imgconvert.csdnimg.cn/aHR0cHM6Ly91c2VyLWdvbGQtY2RuLnhpdHUuaW8vMjAxOS8zLzI3LzE2OWJlMmNlNDA4YTUzYmQ?x-oss-process=image/format,png)

react 在新版本中也加入了`useEffect`，将以前的多个 life\-cycles 合并、重组，使逻辑更加清晰，这里就不展开了。那 vue 是不是也可以这样做？我去了看了一下官方的 `vue-hooks`的 [源码](https://github.com/yyx990803/vue-hooks/blob/master/index.js) 发现了一个新的 api：`$on('hook:xxx')`。有了它，我们就能将之前的代码用更简单和清楚地方式实现了。

![](https://imgconvert.csdnimg.cn/aHR0cHM6Ly91c2VyLWdvbGQtY2RuLnhpdHUuaW8vMjAxOS8zLzI3LzE2OWJlMmNlNDFmY2MyMzI?x-oss-process=image/format,png)

和 react 的`useEffect`有异曲同工之妙。

而且我们有了这个 api 之后，能干的事情还不止这个。有时候我们会用一些第三方组件，比如我们有一个编辑器组件（加载比较慢，会有白屏），所以我们在它渲染完成之前需要给它一个占位符，但可能这个组件并没有暴露给我们这个接口，当然我们需要修改这个组件，在它创建的时候手动 emit 一个事件出去，然后在组件上监听它，比如：

![](https://imgconvert.csdnimg.cn/aHR0cHM6Ly91c2VyLWdvbGQtY2RuLnhpdHUuaW8vMjAxOS8zLzI3LzE2OWJlMmNlNDVlYWJkOGE?x-oss-process=image/format,png)

当然这也是可行的，但万一还要监听一个更新或者摧毁的生命周期呢？其实利用 `hook`可以很方便的实现这个效果。

![](https://imgconvert.csdnimg.cn/aHR0cHM6Ly91c2VyLWdvbGQtY2RuLnhpdHUuaW8vMjAxOS8zLzI3LzE2OWJlMzBlZTUzMGE0NWI?x-oss-process=image/format,png)

当然在 vue 3.0 版本中可能会有新的写法，就不如下面的讨论: [Dynamic Lifecycle Injection](https://github.com/vuejs/rfcs/pull/23)。有兴趣的可以自行去研究，这里就不展开了。当 3.0 正式发布之后再来讨论吧。