---
title: 实现vuex与组件data之间的数据同步更新
tags:
  - Vue
categories:
  - 前端
  - Vue
date: 2019-05-16 22:06:39
---
# 问题

我们都知道，在Vue组件中，`data`部分的数据与视图之间是可以同步更新的，假如我们更新了`data`中的数据，那么视图上的数据就会被同步更新，这就是Vue所谓的数据驱动视图思想。

当我们使用Vuex时，我们也可以通过在视图上通过 `$store.state.[DataKey]` 来获取Vuex中 `state` 的数据，且当 `state` 中的数据发生变化时，视图上的数据也是可以同步更新的，这似乎看起来很顺利。

但是当我们想要通过将 `state` 中的数据绑定到Vue组件的 `data` 上，然后再在视图上去调用 `data` ，如下：

```html
<template>
  <div>{{userInfo}}</div> 
</template>

<script>
export default {
  data() {
    return {
      userInfo: this.$store.state.userInfo;
    };
  }
};
</script>
```

那么我们就会发现，当我们去改变 `state` 中的 `userInfo` 时，视图是不会更新的，相对应的 `data` 中的 `userInfo` 也不会被更改，因为这种调用方式是非常规的。

当Vue在组件加载完毕前，会将 `data` 中的所有数据初始化完毕，之后便只会被动改变数据。然而等组件数据初始化完毕之后，即使 `state` 中的数据发生了改变， `data` 中的数据与其并非存在绑定关系，`data` 仅仅在数据初始化阶段去调用了 `state` 中的数据，所以 `data` 中的数据并不会根据 `state` 中的数据发生改变而改变。

所以如果想在视图上实现与 `state` 中的数据保持同步更新的话，只能采用以下方式：

```html
<template>
  <div>{{$store.state.userInfo}}</div> 
</template>
```

# 解决

那么如果我们必须想要在 `data` 上绑定 `state` 中的数据，让 `state` 去驱动 `data` 发生改变，那我们该如何做呢？

我们可以尝试以下两中方法：

## 1. 使用computed属性去获取state中的数据

这种方式其实并非是去调用了 `data` 中的数据，而是为组件添加了一个计算 `computed` 属性。`computed` 通常用于复杂数据的计算，它实际上是一个函数，在函数内部进行预算后，返回一个运算结果，同时它有一个重要的特性：**当在它内部需要进行预算的数据发生改变后，它重新进行数据运算并返回结果。** 所以，我们可以用 `computed` 去返回 `state` 中的数据，当 `state` 中的数据发生改变后，`computed` 会感知到，并重新获取 `state` 中的数据，并返回新的值。

```html
<template>
  <div>{{userInfo}}</div> 
</template>

<script>
export default {
  computed: {
    userInfo(){
      return this.$store.state.userInfo;
    }
  }
};
</script>
```

## 2. 使用watch监听state中的数据

这种方式就很好理解了，就是通过组件的 `watch` 属性，为 `state` 中的某一项数据添加一个监听，当数据发生改变的时候触发监听事件，在监听事件内部中去更改 `data` 中对应的数据，即可变相的让 `data` 中的数据去根据 `state` 中的数据发生改变而改变。

```html
<template>
  <div>{{userInfo}}</div> 
</template>

<script>
export default {
  data() {
    return {
      userInfo: this.$store.state.userInfo;
    };
  },
  watch: {
    "this.$store.state.userInfo"() {
      this.userInfo = this.$store.getters.getUserInfo; // 按照规范在这里应该去使用getters来获取数据
    }
  }
};
</script>
```