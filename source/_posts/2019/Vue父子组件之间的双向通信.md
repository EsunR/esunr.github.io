---
title: Vue父子组件之间的双向通信
tags: [Vue]
categories:
  - Front
  - Vue
date: 2019-12-29 16:02:32
---

Vue 与 React 为了防止父子组件之间的数据混乱，所以为设计为单项数据流，即父组件仅向子组件传递数据，而子组件无法修改父组件传入的数据，从而影响父组件中的数据。然而在 Vue 中，双向数据流还是可以通过很多方法实现的，比如 `v-model` 双向绑定就是 Vue 提供的一个数据双向绑定的概念，也是 Vue 的特性之一，除此之外，

# 1. v-model

`v-model` 可以绑定于 `input` 控件上实现数据的双向绑定，在 Vue2.2.0+ 中新增了自定义组件的 `v-model` 可以实现对组件内的数据绑定，我们可以借助 `v-model` 来实现向组件内传入数据并且组件内可以修改该数据。

我们以封装一个 Input 组件为示例，我们首先编写一个子组件，上面挂载一个 `model` 属性，同时设置一个 `props`，其中 `props` 设置的参数需要于 `model` 中的 `prop` 字段对应：

```js
<template>
  <div class="clip-input">
    <input type="text" />
  </div>
</template>

<script>
export default {
  name: "Input",
  model: {
    prop: "value",
    event: "input"
  },
  props: {
    value: {
      type: String,
      default: ""
    }
  }
}
</script>
```

我们在组件上设置的 `model` 对象拥有两个属性 `prop` 与 `event`：

`prop` 为 `v-model` 传入的值被挂载到该组件 `$attrs` 上的对应值，如果设置了对应的 `props` 属性就可以接受到这个值（如果设置了 `props` 那 `$attrs` 上对应的值就会被删除）。如以上示例，我们在组件内就可以通过调用 `this.props.value` 调用到 `v-model` 传入的值。

`event` 是一个可触发的事件，在组件内可以使用 `this.$emit("event", newValue)` 来触发这个事件用来修改 `v-model` 中传入的值，并将其值修改为 `newValue`。

在上面的示例中，我们只接受到了父级组件绑定在子组件中的值，但是未向外修改该值，对于上述的组件来说，我们需要在 Input 组件初始化时接受这个值，在文本框文字变动时，来修改这个值，那么利用原生 `<input>` 组件的 `v-model` 指令与组件的 `computed` 属性就可以实现这一效果：

```js
<template>
  <div class="clip-input">
    <input type="text" v-model="inputValue" />
  </div>
</template>

<script>
export default {
  name: "Input",
  model: {
    prop: "value",
    event: "input"
  },
  props: {
    value: {
      type: String,
      default: ""
    }
  }
  computed: {
    inputValue: {
      get() {
        // 当父组件改变 v-model 的值时，在这里重新计算值 inputValue 的值
        return this.value
      },
      set(newVal) {
        // 当子组件修改了 inputValue 的值（通过 input 的 v-model）时，在这里修改父组件绑定的值
        // 之后就可以引发重新 get
        this.$emit("input", newVal)
      }
    }
  }
}
</script>
```

