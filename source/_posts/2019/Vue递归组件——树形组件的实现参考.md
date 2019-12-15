---
title: Vue递归组件——树形组件的实现参考
tags: [Demo]
categories:
  - Front
  - Vue
date: 2019-12-15 19:22:52
---

# 1. 组件的调用方式

```json
<template>
  <div class="tree">
    <Tree :treeData="tree"></Tree>
  </div>
</template>

<script>
import Tree from "./components/Tree";
export default {
  components: {
    Tree
  },
  data() {
    return {
      tree: [
        {
          id: "1",
          title: "1",
          next: [
            {
              id: "1-1",
              title: "1-1",
              next: [
                {
                  id: "1-1-1",
                  title: "1-1-1"
                }
              ]
            },
            {
              id: "1-2",
              title: "1-2"
            }
          ]
        },
        {
          id: "2",
          title: "2",
          next: [
            {
              id: "2-1",
              title: "2-1",
              next: [
                {
                  id: "2-1-1",
                  title: "2-1-1"
                }
              ]
            },
            {
              id: "2-2",
              title: "2-2"
            }
          ]
        }
      ]
    };
  }
};
</script>
```

# 2. 父级组件

父级组件组要是负责接受整个数据，遍历最外层的节点内容：

```js
// components/Tree/index.vue
<template>
  <div class="tree">
    <Item v-for="item in treeData" :key="item.id" :nodeData="item"></Item>
  </div>
</template>

<script>
import Item from "./subcomponents/Item";
export default {
  name: "Tree",
  components: {
    Item
  },
  data() {
    return {};
  },
  props: {
    treeData: {
      type: Array,
      required: true
    }
  }
};
</script>

<style lang="css" scpoed>
.tree {
  margin-left: -20px;
}
</style>
```

# 3. 节点组件

节点组件负责渲染节点本身，分为两种情况渲染：

1. 节点没有子节点，就输出单独一个节点内容
2. 节点有子节点，渲染输出自己节点的内容同时，再循环遍历子节点的每个节点内容

```js
// components/Tree/subcomponents/Item.vue
<template>
  <div class="node" id="nodeData.id" v-if="nodeData.next">
    <a class="floder">Floder : {{ nodeData.title }}</a>
    <Node
      v-for="subItem in nodeData.next"
      :key="subItem.id"
      :nodeData="subItem"
    ></Node>
  </div>
  <div class="node" v-else>
    <span class="file">file : {{ nodeData.title }}</span>
  </div>
</template>

<script>
export default {
  name: "Node",
  data() {
    return {};
  },
  props: {
    nodeData: {
      type: Object,
      required: true
    }
  }
};
</script>

<style scope>
.node {
  margin: 5px 0;
  margin-left: 20px;
}
.floder {
  font-weight: bold;
}
</style>
```

> 后记：其实再 Item 组件中可以通过调用父级的 Tree 组件也可以实现对当前组件的递归调用。但是再 Vue 的子组件中如果调用父组件的话，会提示没有注册相应的组件，这应该是 Vue 为了防止组件循环调用而禁止了子组件去调用父组件吧。